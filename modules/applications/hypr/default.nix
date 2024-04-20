{ config, pkgs, lib, vars, ... }: {

  imports = [
    ./hyprland.nix
    ./hypridle.nix
    ./hyprlock.nix
  ];

}
