{ config, pkgs, ... }:
{
  sops.secrets."services/attic/token" = { };

  launchd.daemons.attic-watch-store = {
    script = ''
      set -euo pipefail
      export HOME=/var/lib/attic-watch-store
      mkdir -p "$HOME"
      ${pkgs.attic-client}/bin/attic login home \
        https://attic.home.arpa "$(cat ${config.sops.secrets."services/attic/token".path})"
      exec ${pkgs.attic-client}/bin/attic watch-store --ignore-upstream-cache-filter -j 2 home:home-cache
    '';
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/var/log/attic-watch-store.stdout.log";
      StandardErrorPath = "/var/log/attic-watch-store.stderr.log";
    };
  };
}
