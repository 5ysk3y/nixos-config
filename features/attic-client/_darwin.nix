{ config, pkgs, ... }:
let
  atticConfig = import ./_config.nix {
    inherit pkgs;
    tokenFile = config.sops.secrets."services/attic/token".path;
  };
in
{
  sops.secrets."services/attic/token" = { };

  launchd.daemons.attic-watch-store = {
    script = ''
      set -euo pipefail
      export HOME=/var/lib/attic-watch-store
      export XDG_CONFIG_HOME=${atticConfig}
      mkdir -p "$HOME"
      exec ${pkgs.attic-client}/bin/attic watch-store --ignore-upstream-cache-filter -j 2 home:home-cache
    '';
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/var/log/attic-watch-store.stdout.log";
      StandardErrorPath = "/var/log/attic-watch-store.stderr.log";
    };
  };

  # Catches up on whatever watch-store missed (see _nixos.nix): pushes the
  # running system's closure, which attic trims to the paths the server
  # lacks. launchd runs a calendar job missed during sleep on wake, so
  # this covers resume too. `rebuild` also starts it after a switch.
  launchd.daemons.attic-push-system = {
    script = ''
      set -euo pipefail
      export HOME=/var/lib/attic-watch-store
      export XDG_CONFIG_HOME=${atticConfig}
      mkdir -p "$HOME"
      exec ${pkgs.attic-client}/bin/attic push --ignore-upstream-cache-filter -j 2 home:home-cache /run/current-system
    '';
    serviceConfig = {
      StartCalendarInterval = [
        {
          Hour = 3;
          Minute = 17;
        }
      ];
      StandardOutPath = "/var/log/attic-push-system.stdout.log";
      StandardErrorPath = "/var/log/attic-push-system.stderr.log";
    };
  };
}
