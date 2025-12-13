{
  pkgs,
  vars,
}:
{
  nix-build-system = pkgs.writeShellApplication {
    name = "nix-build-system";
    runtimeInputs = with pkgs; [
      nvd
      gawk
      gnused
    ];
    text = ''
      CONFIG="${vars.nixos-config}"
      HOME="/home/${vars.username}"
      OUTFILE="changes_$(date +%d-%m@%T).out"

      echo "Welcome!"
      if [ ! -f $CONFIG/flake.lock.bak ]; then
        echo "Backing up flake lock file"
        cp $CONFIG/flake.lock $CONFIG/flake.lock.bak
        echo "Done"
        echo ""
      else
        echo "WARNING: flake.lock backup already exists, not backing up."
        echo ""
      fi
      cd $CONFIG
      nix flake update
      echo ""
      echo "Flake updated"
      cd $HOME
      echo "Beginning build. This may take some time."
      echo ""
      systemd-inhibit --no-pager --no-legend --mode=block --who='${vars.username}' --why='NixOS System Building' sudo nixos-rebuild --flake $CONFIG build --option eval-cache false --show-trace

      echo ""
      echo "Build complete. Providing result:"
      echo ""
      nvd diff /run/current-system $HOME/result > "$OUTFILE"

      #Cleanup
      awk -i inplace '{$0=gensub(/\s*\S+/,"",2)}1' "$OUTFILE"
      sed -i -e '1,2d' -e 's/Version/Changed\/Updated:/g' -e 's/Added/\nAdded:/g' -e 's/Removed/\nRemoved:/g' -e '$d' "$OUTFILE"
      rm $HOME/result

      cat "$OUTFILE"

      echo "Result has been stored in $HOME/$OUTFILE. Finished"
    '';
  };

  nix-secrets = pkgs.writeShellApplication {
    name = "nix-secrets";
    runtimeInputs = with pkgs; [
      git
      coreutils
    ];
    text = ''
          set -euo pipefail

          USER_NAME="${vars.username}"
          USER_HOME="/home/$USER_NAME"
          CONFIG_DIR="${vars.nixos-config}"

          GIT_DIR="$USER_HOME/.cache/nix-secrets.git"
          WORK_TREE="/etc/nixos/nix-secrets"
          ORIGIN="git@github.com:5ysk3y/nix-secrets.git"
          BRANCH="main"

          cmd="''${1:-}"
          shift || true

          # Who should own/fetch the bare repo?
          INVOKER="''${SUDO_USER:-$USER_NAME}"

          die() { echo "ERROR: $*" >&2; exit 1; }

          as_invoker() {
            sudo -u "$INVOKER" -H -- "$@"
          }

          as_root() {
            sudo -- "$@"
          }

          ensure_bare_repo() {
            if [ ! -d "$GIT_DIR" ]; then
              echo "Cloning bare repo as $INVOKER to $GIT_DIR..."
              as_invoker mkdir -p "$(dirname "$GIT_DIR")"
              as_invoker git clone --bare "$ORIGIN" "$GIT_DIR"
            fi

            # If the repo exists but is broken due to ownership, fail loudly with guidance.
            as_invoker git --git-dir="$GIT_DIR" rev-parse --git-dir >/dev/null 2>&1 || {
              cat >&2 <<EOF
      ERROR: Bare repo at $GIT_DIR is not usable as $INVOKER.

      This usually means root-owned files exist inside it (e.g. HEAD mode 0600).
      Fix with:
        sudo chown -R $INVOKER:users "$GIT_DIR"
        sudo find "$GIT_DIR" -type d -exec chmod 700 {} \;
        sudo find "$GIT_DIR" -type f -exec chmod 600 {} \;
      EOF
              exit 1
            }

            echo "Fetching origin/$BRANCH as $INVOKER..."
            as_invoker git --git-dir="$GIT_DIR" fetch origin "$BRANCH:refs/remotes/origin/$BRANCH"

            # Guardrail: ensure bare repo ownership stays with the user.
            as_root chown -R "$INVOKER:users" "$GIT_DIR" || true
            as_root find "$GIT_DIR" -type d -exec chmod 700 {} \; >/dev/null 2>&1 || true
            as_root find "$GIT_DIR" -type f -exec chmod 600 {} \; >/dev/null 2>&1 || true
          }

          deploy_worktree() {
            echo "Deploying work-tree to $WORK_TREE..."
            as_root mkdir -p "$WORK_TREE"

            # Checkout/reset using already-fetched ref (no network here, no agent, no yubikey).
            as_root git -c safe.directory="$WORK_TREE" \
              --git-dir="$GIT_DIR" --work-tree="$WORK_TREE" \
              checkout -f -B "$BRANCH" "refs/remotes/origin/$BRANCH"

            as_root git -c safe.directory="$WORK_TREE" \
              --git-dir="$GIT_DIR" --work-tree="$WORK_TREE" \
              reset --hard "refs/remotes/origin/$BRANCH"

            # Root owns deployed secrets, locked down.
            as_root chown -R root:root "$WORK_TREE"
            as_root chmod -R go-rwx "$WORK_TREE" || true

            # Guardrail again: if root touched the bare repo, put it back.
            as_root chown -R "$INVOKER:users" "$GIT_DIR" || true
            as_root find "$GIT_DIR" -type d -exec chmod 700 {} \; >/dev/null 2>&1 || true
            as_root find "$GIT_DIR" -type f -exec chmod 600 {} \; >/dev/null 2>&1 || true
          }

          update_flake_lock() {
            if [ -d "$CONFIG_DIR" ]; then
              echo "Updating flake.lock input nix-secrets in $CONFIG_DIR..."
              as_root nix flake lock --update-input nix-secrets "$CONFIG_DIR"
            fi
          }

          init() {
            ensure_bare_repo
            deploy_worktree
            echo "Done."
          }

          update() {
            ensure_bare_repo
            deploy_worktree
            update_flake_lock
            echo "Done."
          }

          status() {
            if [ ! -d "$GIT_DIR" ]; then
              echo "Not initialised."
              exit 1
            fi
            as_invoker git --git-dir="$GIT_DIR" remote -v
            as_invoker git --git-dir="$GIT_DIR" show -s --oneline --decorate || true
            echo "Work-tree: $WORK_TREE"
            as_root test -d "$WORK_TREE" && as_root ls -la "$WORK_TREE" | head -n 5 || true
          }

          case "$cmd" in
            init) init ;;
            update|pull) update ;;
            status) status ;;
            ""|help|-h|--help)
              cat <<EOF
      Usage: nix-secrets <command>

      Commands:
        init        Fetch into $GIT_DIR (as $INVOKER) and deploy to $WORK_TREE (as root)
        update      Fetch + deploy, then update flake.lock input nix-secrets in $CONFIG_DIR
        status      Show current commit/remote from $GIT_DIR

      Notes:
        - Run as your user:   nix-secrets update
        - Running via sudo is fine too; it will still fetch as the invoking user.
      EOF
              ;;
            *)
              echo "Unknown command: $cmd"
              exit 2
              ;;
          esac
    '';
  };
}
