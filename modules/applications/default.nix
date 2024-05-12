{ pkgs, lib, ... }: {
  imports = [
    ./doomemacs
    ./hypr
    ./qutebrowser
    ./fuzzel
    ./waybar
  ];
}
