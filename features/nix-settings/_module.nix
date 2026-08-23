{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  nix = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    gc = {
      automatic = true;
      options = "-d";
    };
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  };

  home.packages = [
    inputs.self.packages.${system}.nix-build-system
  ]
  ++ (with pkgs; [
    nixfmt
    nixd
    statix
  ]);
}
