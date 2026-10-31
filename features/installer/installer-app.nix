# nix run .#build-installer -- iso|netboot
#
# Builds the x86_64 installer ISO or netboot tree from the repo root.
# - x86_64-linux: builds natively.
# - aarch64-darwin: starts the nix-darwin linux-builder VM (Rosetta) if it
#   isn't already running, and stops it again afterwards. Needs the
#   linux-builder feature enabled on the host (provides the `linux-builder`
#   helper).
# It never writes a USB stick or pushes netboot files on its own: it prints
# the next command. For netboot, setting NETBOOT_DEST=<host>:<assets>/nixos-installer/
# gets you an opt-in [y/N] push prompt (default no). The destination stays out
# of the repo.
_: {
  perSystem =
    { pkgs, lib, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) isDarwin;
      rsync = lib.getExe pkgs.rsync;

      darwinBuilder = ''
        command -v linux-builder >/dev/null || {
          echo "error: linux-builder helper not found; enable the linux-builder feature on this host" >&2
          exit 1
        }

        echo ">> sudo is needed to manage the linux-builder VM"
        sudo -v

        builder_up() {
          sudo ssh -o BatchMode=yes -o ConnectTimeout=5 \
            -o StrictHostKeyChecking=accept-new linux-builder true 2>/dev/null
        }

        if ! builder_up; then
          echo ">> starting linux-builder VM"
          linux-builder start
          stop_builder() {
            trap - EXIT
            echo ">> stopping linux-builder VM"
            linux-builder stop
          }
          trap stop_builder EXIT
          for _ in {1..60}; do
            builder_up && break
            sleep 3
          done
          builder_up || {
            echo "error: builder not reachable after ~3 minutes; check Console.app, subsystem systems.applicative.vzvm" >&2
            exit 1
          }
        else
          echo ">> linux-builder already running; leaving it running afterwards"
        fi
      '';

      usbHint =
        if isDarwin then
          ''
            echo "   diskutil list                          # identify the stick, e.g. disk4"
            echo "   diskutil unmountDisk /dev/diskN"
            echo "   sudo dd if=$iso of=/dev/rdiskN bs=4m   # Ctrl+T shows progress"
            echo "   diskutil eject /dev/diskN"
          ''
        else
          ''
            echo "   lsblk                                  # identify the stick, e.g. sdb"
            echo "   sudo dd if=$iso of=/dev/sdX bs=4M status=progress conv=fsync"
          '';

      script = pkgs.writeShellApplication {
        name = "build-installer";
        text = ''
          usage() {
            echo "usage: nix run .#build-installer -- iso|netboot" >&2
            exit 64
          }
          [[ $# -eq 1 ]] || usage
          case "$1" in
            iso) attr=installer; target=isoImage ;;
            netboot) attr=installer-netboot; target=netbootTree ;;
            *) usage ;;
          esac
          out="result-$attr"

          [[ -f flake.nix ]] || {
            echo "error: run this from the nixos-config repo root" >&2
            exit 1
          }

          stop_builder() { :; }
          ${lib.optionalString isDarwin darwinBuilder}

          nix build ".#nixosConfigurations.$attr.config.system.build.$target" --out-link "$out" -L

          stop_builder

          echo
          if [[ $1 == iso ]]; then
            isos=("$out"/iso/*.iso)
            iso=''${isos[0]}
            echo ">> ISO built: $iso ($(du -h "$iso" | cut -f1))"
            echo ">> Nothing has been written. To write a USB stick (this ERASES it):"
            ${usbHint}
          else
            dest=''${NETBOOT_DEST:-}
            echo ">> netboot tree built: $out/"
            if [[ -z $dest ]]; then
              echo ">> To publish it to the netboot.xyz assets directory:"
              echo "   ${rsync} -rL --chmod=F644 $out/ <host>:<assets>/nixos-installer/"
              echo "   (or set NETBOOT_DEST=<host>:<assets>/nixos-installer/ to be offered a push)"
            else
              echo ">> Publish command:"
              echo "   ${rsync} -rL --chmod=F644 $out/ $dest"
              if [[ -t 0 ]]; then
                read -r -p ">> Push now? [y/N] " reply || reply=
                if [[ $reply == [yY]* ]]; then
                  "${rsync}" -rL --chmod=F644 "$out/" "$dest"
                  echo ">> pushed"
                fi
              fi
            fi
            echo ">> netboot.xyz: /config/menus/local-vars.ipxe should contain"
            echo "   set custom_url http://<host>:8080/nixos-installer"
          fi
        '';
      };
    in
    {
      apps.build-installer = {
        type = "app";
        program = lib.getExe script;
        meta.description = "Build the x86_64 installer ISO or netboot tree (linux-builder VM on macOS)";
      };
    };
}
