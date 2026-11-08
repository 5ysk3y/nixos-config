{
  pkgs,
  inputs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  home.packages = with pkgs; [
    nixfmt
    nixd
    statix
    inputs.self.packages.${system}.nix-build-system
  ];
}
