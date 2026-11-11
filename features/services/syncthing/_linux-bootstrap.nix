{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    filterAttrs
    escapeShellArg
    ;

  cfg = config.features.home.syncthing;

  topology = import ./_topology.nix;

  bootstrapFolders = filterAttrs (_: f: f.enable && f.bootstrap.enable) cfg.folders;

  firstBootstrapFolder = builtins.head (builtins.attrNames bootstrapFolders);

  folderCfg = bootstrapFolders.${firstBootstrapFolder};

  inherit (folderCfg.bootstrap) markerFile;
  folderPath = folderCfg.path;
  # Restored once the first sync completes
  finalType = folderCfg.type;
  # The REST API addresses folders by their Syncthing ID, not this option's name
  folderId = topology.folders.${firstBootstrapFolder}.id;

  syncthingConfigFile = "${config.home.homeDirectory}/.local/state/syncthing/config.xml";

  # syncthing-init adds the folder as its declared type and Syncthing scans it
  # straight away, before the bootstrap can make it receive-only. Anything
  # recorded by that scan is a genuine local version, so a revert keeps it
  # and it is sent to the cluster once connected (stale files from a
  # restored ~/Sync, files the cluster has since deleted). Ignoring
  # everything until the bootstrap takes over keeps that first scan empty.
  ignoreFile = "${folderPath}/.stignore";
  savedIgnoreFile = "${folderPath}/.stignore.pre-bootstrap";
  holdLine = "// syncthing-bootstrap: ignore everything until the first sync";
in
{
  config = mkIf (pkgs.stdenv.hostPlatform.isLinux && bootstrapFolders != { }) {
    systemd.user.services.syncthing-bootstrap-hold = {
      Unit = {
        Description = "Hold the Syncthing bootstrap folder until its first sync";
        Before = [ "syncthing.service" ];
        ConditionPathExists = "!${markerFile}";
      };

      Service = {
        Type = "oneshot";
        ExecStart = lib.getExe (
          pkgs.writeShellApplication {
            name = "syncthing-bootstrap-hold";
            runtimeInputs = [ pkgs.coreutils ];
            text = ''
              ignore_file=${escapeShellArg ignoreFile}
              saved=${escapeShellArg savedIgnoreFile}
              hold_line=${escapeShellArg holdLine}

              mkdir -p ${escapeShellArg "${folderPath}/.stfolder"}

              if [ -e "$ignore_file" ] && [ "$(head -n1 "$ignore_file")" = "$hold_line" ]; then
                exit 0
              fi
              # Keep a restored .stignore to put back after the first sync
              if [ -e "$ignore_file" ]; then
                mv -f "$ignore_file" "$saved"
              fi
              printf '%s\n' "$hold_line" '*' >"$ignore_file"
            '';
          }
        );
      };

      Install.WantedBy = [ "syncthing.service" ];
    };

    systemd.user.services.syncthing-bootstrap = {
      Unit = {
        Description = "Safe first-sync bootstrap for Syncthing";
        Wants = [
          "syncthing.service"
          "syncthing-init.service"
        ];
        After = [
          "syncthing.service"
          "syncthing-init.service"
        ];
        ConditionPathExists = "!${markerFile}";
      };

      # Type=exec rather than oneshot: a first sync can take far longer than
      # any sane start timeout, and nothing should wait on it. If the script
      # fails part-way the folder stays receive-only (the safe state) and
      # systemd retries; the marker is only written once fully in sync.
      Service = {
        Type = "exec";
        Restart = "on-failure";
        RestartSec = "30s";
        ExecStart = lib.getExe (
          pkgs.writeShellApplication {
            name = "syncthing-bootstrap";
            runtimeInputs = with pkgs; [
              coreutils
              curl
              gnused
              jq
            ];
            text = ''
              marker=${escapeShellArg markerFile}
              folder_path=${escapeShellArg folderPath}
              folder_id=${escapeShellArg folderId}
              config_file=${escapeShellArg syncthingConfigFile}
              ignore_file=${escapeShellArg ignoreFile}
              saved_ignore_file=${escapeShellArg savedIgnoreFile}
              hold_line=${escapeShellArg holdLine}

              mkdir -p "$folder_path/.stfolder" "$(dirname "$marker")"

              for _ in $(seq 1 60); do
                [ -f "$config_file" ] && break
                sleep 2
              done
              [ -f "$config_file" ] || {
                echo "Timed out waiting for Syncthing config at $config_file" >&2
                exit 1
              }

              token="$(sed -n 's:.*<apikey>\(.*\)</apikey>.*:\1:p' "$config_file" | head -n1)"
              [ -n "$token" ] || {
                echo "Failed to read Syncthing API key from $config_file" >&2
                exit 1
              }

              # The GUI may serve plain HTTP or TLS; probe both until it answers
              api_base=""
              curl_extra=()
              for _ in $(seq 1 60); do
                if curl -fsS "http://127.0.0.1:8384/rest/noauth/health" >/dev/null 2>&1; then
                  api_base="http://127.0.0.1:8384"
                  break
                fi
                if curl -kfsS "https://127.0.0.1:8384/rest/noauth/health" >/dev/null 2>&1; then
                  api_base="https://127.0.0.1:8384"
                  curl_extra=(-k)
                  break
                fi
                sleep 2
              done
              [ -n "$api_base" ] || {
                echo "Timed out waiting for the Syncthing API" >&2
                exit 1
              }

              api() {
                local path="$1"
                shift
                curl "''${curl_extra[@]}" -fsS -H "Authorization: Bearer $token" "$@" "$api_base$path"
              }

              # home-manager's syncthing-init re-posts the folder config (with
              # its declared type) on every switch, so re-assert this while waiting
              ensure_receiveonly() {
                if [ "$(api "/rest/config/folders/$folder_id" | jq -r '.type')" != receiveonly ]; then
                  api "/rest/config/folders/$folder_id" -X PATCH \
                    -H "Content-Type: application/json" \
                    --data '{"type":"receiveonly"}' >/dev/null
                fi
              }

              ensure_receiveonly

              my_id="$(api /rest/system/status | jq -r '.myID')"
              mapfile -t peers < <(
                api "/rest/config/folders/$folder_id" \
                  | jq -r --arg me "$my_id" '.devices[].deviceID | select(. != $me)'
              )
              [ "''${#peers[@]}" -gt 0 ] || {
                echo "Folder $folder_id is not shared with any peer" >&2
                exit 1
              }

              # Until a peer's index has arrived, the local device is the only
              # source of the global state, so "fully synced" is trivially true
              # and a revert has nothing to revert to. Wait for a connected peer
              # that shares the folder (remoteState valid) and whose index we
              # hold (sequence > 0). Times out after an hour; systemd retries.
              peer=""
              for _ in $(seq 1 360); do
                for p in "''${peers[@]}"; do
                  if api "/rest/db/completion?folder=$folder_id&device=$p" \
                    | jq -e '.remoteState == "valid" and .sequence > 0' >/dev/null; then
                    peer="$p"
                    break 2
                  fi
                done
                ensure_receiveonly
                sleep 10
              done
              [ -n "$peer" ] || {
                echo "Timed out waiting for a peer to share folder $folder_id" >&2
                exit 1
              }
              echo "Peer $peer is sharing $folder_id; reverting local changes"

              # Lift the hold now the folder is receive-only, so the rescan
              # flags local-only and stale files as local changes to revert
              ensure_receiveonly
              if [ -e "$ignore_file" ] && [ "$(head -n1 "$ignore_file")" = "$hold_line" ]; then
                if [ -e "$saved_ignore_file" ]; then
                  mv -f "$saved_ignore_file" "$ignore_file"
                else
                  rm -f "$ignore_file"
                fi
              fi

              # Synchronous: returns once the scan has finished
              api "/rest/db/scan?folder=$folder_id" -X POST >/dev/null
              api "/rest/db/revert?folder=$folder_id" -X POST >/dev/null

              # In sync once there's nothing left to pull, nothing changed
              # locally, the folder is idle and the peer's index has stopped
              # moving, held for three polls in a row so an index still
              # arriving in batches can't end it early.
              stable=0
              last_seq=""
              while [ "$stable" -lt 3 ]; do
                sleep 10
                ensure_receiveonly
                status="$(api "/rest/db/status?folder=$folder_id")"
                seq_now="$(api "/rest/db/completion?folder=$folder_id&device=$peer" | jq -r '.sequence')"

                if [ "$(jq -r '.receiveOnlyTotalItems' <<<"$status")" -gt 0 ]; then
                  api "/rest/db/revert?folder=$folder_id" -X POST >/dev/null
                  stable=0
                elif jq -e '.state == "idle" and .needTotalItems == 0' <<<"$status" >/dev/null \
                  && [ "$seq_now" = "$last_seq" ]; then
                  stable=$((stable + 1))
                else
                  stable=0
                fi
                last_seq="$seq_now"
              done

              jq -n --arg type ${escapeShellArg finalType} '{type: $type}' \
                | api "/rest/config/folders/$folder_id" -X PATCH \
                  -H "Content-Type: application/json" --data @- >/dev/null

              touch "$marker"
              echo "Bootstrap of $folder_id complete"
            '';
          }
        );
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
