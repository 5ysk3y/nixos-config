{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib) optional;
  inherit (pkgs.stdenv.hostPlatform) isLinux system;
in
{
  nix = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    gc = {
      automatic = true;
      options = "-d";
    };
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  };

  home.packages =
    optional isLinux inputs.self.packages.${system}.nix-build-system
    ++ (with pkgs; [
      nixfmt
      nixd
      statix
    ]);
}
