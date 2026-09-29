{
  config,
  pkgs,
  ...
}:
let
  atticConfig = import ./_config.nix {
    inherit pkgs;
    tokenFile = config.sops.secrets."services/attic/token".path;
  };
in
{
  users.groups.attic-watch-store = { };
  users.users.attic-watch-store = {
    isSystemUser = true;
    group = "attic-watch-store";
  };

  sops.secrets."services/attic/token" = {
    owner = config.users.users.attic-watch-store.name;
  };

  systemd.services.attic-watch-store = {
    description = "Push new Nix store paths to attic";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      User = "attic-watch-store";
      Group = "attic-watch-store";
      Type = "simple";
      StateDirectory = "attic-watch-store";
      Environment = [
        "HOME=%S/attic-watch-store"
        "XDG_CONFIG_HOME=${atticConfig}"
      ];
      ExecStart = "${pkgs.attic-client}/bin/attic watch-store --ignore-upstream-cache-filter -j 2 home:home-cache";
      Restart = "on-failure";
      RestartSec = 10;
    };
  };
}
