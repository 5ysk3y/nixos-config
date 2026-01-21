{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./applications
    ./conf
    ./scripts
  ];

  # Application Defaults

  applications = with lib; {
    hypr = {
      enable = mkDefault pkgs.stdenv.hostPlatform.isLinux;
      apps = {
        hyprland = mkDefault pkgs.stdenv.hostPlatform.isLinux;
        hyprlock = mkDefault pkgs.stdenv.hostPlatform.isLinux;
        hypridle = mkDefault pkgs.stdenv.hostPlatform.isLinux;
      };
    };
    waybar = mkDefault pkgs.stdenv.hostPlatform.isLinux;
    doomemacs = mkDefault true;
    qutebrowser = mkDefault true;
    fuzzel = mkDefault pkgs.stdenv.hostPlatform.isLinux;
  };

  # Symlinked Config File Defaults

  confSymlinks = with lib; {
    enable = mkDefault false;
    configs = {
      gnupg = mkDefault true;
      jellyfinShim = mkDefault true;
      openrgb = mkDefault true;
      ssh = mkDefault true;
      streamdeckui = mkDefault false;
      wallpapers = mkDefault true;
      webcord = mkDefault true;
    };
  };

  # Script Defaults

  scripts = with lib; {
    enable = mkDefault pkgs.stdenv.hostPlatform.isLinux;
    gaming = mkDefault pkgs.stdenv.hostPlatform.isLinux;
    nix = mkDefault pkgs.stdenv.hostPlatform.isLinux;
  };
}
