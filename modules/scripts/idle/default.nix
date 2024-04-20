{ config, lib, pkgs, home-manager, ... }: {
  home.packages = with pkgs; [
    (import ./dim_screen.nix {inherit pkgs;})
    (import ./undim_screen.nix {inherit pkgs;})
  ];
}
