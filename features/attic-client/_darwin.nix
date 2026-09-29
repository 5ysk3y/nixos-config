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
}
