{ pkgs, lib, ... }: {
  imports = [
    ./doomemacs
    ./hypr
    ./qutebrowser
    ./rofi
    ./waybar
  ];
}
