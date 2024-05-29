{ config, lib, pkgs, ... }: {

  imports = [
    ./applications
    ./conf
    ./scripts
  ];

  # Application Defaults

  applications = with lib; {
   hypr = {
      enable = mkDefault false;
      apps = {
        hyprland = mkDefault true;
        hyprlock = mkDefault true;
        hypridle = mkDefault true;
      };
    };
    waybar = mkDefault true;
    doomemacs = mkDefault true;
    qutebrowser = mkDefault true;
    fuzzel = mkDefault true;
  };

  # Symlinked Config File Defaults

  confSymlinks = with lib; {
    enable = mkDefault true;
    configs = {
      gnupg = mkDefault true;
      jellyfinShim = mkDefault false;
      openrgb = mkDefault false;
      qpwgraph = mkDefault false;
      ssh = mkDefault true;
      streamdeckui = mkDefault false;
      wallpapers = mkDefault true;
      webcord = mkDefault false;
    };
  };

  # Script Defaults

  scripts = with lib; {
    enable = mkDefault false;
    gaming = mkDefault true;
    nix = mkDefault true;
  };
}
