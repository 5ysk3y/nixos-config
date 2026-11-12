{ config, pkgs, ... }:
let
  atticConfig = import ./_config.nix {
    inherit pkgs;
    tokenFile = config.sops.secrets."services/attic/token".path;
  };
in
{
  sops.secrets."services/attic/token" = { };

  # Only paths cache.nixos.org doesn't serve, one at a time: see _nixos.nix
  launchd.daemons.attic-watch-store = {
    script = ''
      set -euo pipefail
      export HOME=/var/lib/attic-watch-store
      export XDG_CONFIG_HOME=${atticConfig}
      mkdir -p "$HOME"
      # attic prints a line to stderr for every path it pushes. launchd
      # opens the log once, so this long-running daemon keeps writing to
      # the same file even after newsyslog renames it. Keep only the
      # failures and other messages, so the file stays small.
      ${pkgs.attic-client}/bin/attic watch-store -j 1 home:home-cache 2>&1 \
        | ${pkgs.gnugrep}/bin/grep --line-buffered -v '^✅'
    '';
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/var/log/attic-watch-store.stdout.log";
      StandardErrorPath = "/var/log/attic-watch-store.stderr.log";
    };
  };

  # launchd appends to these and nothing trims them. Rotated by size: N
  # because neither job has a PID file to signal. attic-push-system exits
  # after each run, so its next run opens a fresh file. watch-store only
  # does so when it restarts (boot, or a switch that changes it).
  system.newsyslog = {
    enable = true;
    files.attic =
      map
        (logfilename: {
          inherit logfilename;
          size = "1024";
          count = 3;
          flags = [
            "Z"
            "N"
          ];
        })
        [
          "/var/log/attic-watch-store.stdout.log"
          "/var/log/attic-watch-store.stderr.log"
          "/var/log/attic-push-system.stdout.log"
          "/var/log/attic-push-system.stderr.log"
        ];
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
      exec ${pkgs.attic-client}/bin/attic push -j 1 home:home-cache /run/current-system
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
