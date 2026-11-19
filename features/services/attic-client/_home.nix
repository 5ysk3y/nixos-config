# My own attic command, for pushing to and managing the cache by hand. Its
# config reads the token from a sops secret, as the push daemons' does, so
# no plaintext token sits in ~/.config/attic.
{ config, pkgs, ... }:
let
  atticConfig = import ./_config.nix {
    inherit pkgs;
    tokenFile = config.sops.secrets."services/attic/token".path;
  };
in
{
  sops.secrets."services/attic/token" = { };

  home.packages = [ pkgs.attic-client ];

  xdg.configFile."attic/config.toml".source = "${atticConfig}/attic/config.toml";
}
