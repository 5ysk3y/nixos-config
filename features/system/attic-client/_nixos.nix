{ config, pkgs, ... }:
{
  sops.secrets."services/attic/token" = { };

  systemd.services.attic-watch-store = {
    description = "Push new Nix store paths to attic";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "simple";
      StateDirectory = "attic-watch-store";
      Environment = "HOME=%S/attic-watch-store";
      ExecStart = pkgs.writeShellScript "attic-watch-store-start" ''
        set -euo pipefail
        ${pkgs.attic-client}/bin/attic login home \
          http://192.168.1.110:8080 "$(cat ${config.sops.secrets."services/attic/token".path})"
        exec ${pkgs.attic-client}/bin/attic watch-store --ignore-upstream-cache-filter -j 1 home:home-cache
      '';
      Restart = "on-failure";
      RestartSec = 10;
    };
  };
}
