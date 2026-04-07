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
    concatMapStringsSep
    escapeShellArg
    ;

  cfg = config.features.home.syncthing;

  bootstrapFolders = filterAttrs (_: f: f.enable && f.bootstrap.enable) cfg.folders;

  firstBootstrapFolder = builtins.head (builtins.attrNames bootstrapFolders);

  folderCfg = bootstrapFolders.${firstBootstrapFolder};

  inherit (folderCfg.bootstrap) markerFile;
  folderPath = folderCfg.path;

  syncthingConfigFile = "${config.home.homeDirectory}/.local/state/syncthing/config.xml";
in
{
  config = mkIf (pkgs.stdenv.isLinux && bootstrapFolders != { }) {
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

      Service = {
        Type = "oneshot";
        TimeoutStartSec = "90s";
        ExecStart = pkgs.writeShellScript "syncthing-bootstrap-start" ''
          set -euo pipefail

          marker=${escapeShellArg markerFile}
          folder_path=${escapeShellArg folderPath}
          config_file=${escapeShellArg syncthingConfigFile}

          mkdir -p "$folder_path/.stfolder"
          mkdir -p "$(dirname "$marker")"

          for _ in $(seq 1 30); do
            [ -f "$config_file" ] && break
            sleep 2
          done

          [ -f "$config_file" ] || {
            echo "Timed out waiting for Syncthing config at $config_file"
            exit 1
          }

          token="$(
            sed -n 's:.*<apikey>\(.*\)</apikey>.*:\1:p' "$config_file" | head -n1
          )"

          [ -n "$token" ] || {
            echo "Failed to read Syncthing API key from $config_file"
            exit 1
          }

          api_base="http://127.0.0.1:8384"
          curl_extra=()

          if ! ${pkgs.curl}/bin/curl -fsS "$api_base/rest/noauth/health" >/dev/null 2>&1; then
            api_base="https://127.0.0.1:8384"
            curl_extra=(-k)
          fi

          for _ in $(seq 1 30); do
            if ${pkgs.curl}/bin/curl "''${curl_extra[@]}" -fsS "$api_base/rest/noauth/health" >/dev/null 2>&1; then
              break
            fi
            sleep 2
          done

          ${pkgs.curl}/bin/curl "''${curl_extra[@]}" -fsS \
            -X PATCH \
            -H "Authorization: Bearer $token" \
            -H "Content-Type: application/json" \
            "$api_base/rest/config/folders/sync" \
            --data '{"type":"receiveonly"}' >/dev/null

          ${pkgs.curl}/bin/curl "''${curl_extra[@]}" -fsS \
            -X POST \
            -H "Authorization: Bearer $token" \
            "$api_base/rest/db/scan?folder=sync" >/dev/null

          sleep 2

          ${pkgs.curl}/bin/curl "''${curl_extra[@]}" -fsS \
            -X POST \
            -H "Authorization: Bearer $token" \
            "$api_base/rest/db/revert?folder=sync" >/dev/null

          for _ in $(seq 1 60); do
            completion="$(
              ${pkgs.curl}/bin/curl "''${curl_extra[@]}" -fsS \
                -H "Authorization: Bearer $token" \
                "$api_base/rest/db/completion?folder=sync" \
              | ${pkgs.jq}/bin/jq -r '.completion'
            )"

            completion_int="''${completion%.*}"

            [ "$completion_int" -ge 100 ] && break
            sleep 2
          done

          ${pkgs.curl}/bin/curl "''${curl_extra[@]}" -fsS \
            -X PATCH \
            -H "Authorization: Bearer $token" \
            -H "Content-Type: application/json" \
            "$api_base/rest/config/folders/sync" \
            --data '{"type":"sendreceive"}' >/dev/null

          touch "$marker"
        '';
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
