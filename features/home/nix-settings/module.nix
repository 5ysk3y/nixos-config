{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  nix = {
    gc = {
      automatic = true;
      options = "-d";
    };
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  };

  home.packages =
    with lib;
    mkIf pkgs.stdenv.hostPlatform.isLinux [
      inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.nix-build-system
    ];
}
