{ config, pkgs, ... }:
{
  gtk = with pkgs; {
    enable = true;
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = bibata-cursors;
    };
    theme = {
      name = "Dracula";
      package = dracula-theme;
    };
    iconTheme = {
      name = "Bibata-Modern-Classic";
      package = bibata-cursors;
    };
    gtk3 = {
      extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
    };
    gtk4 = {
      inherit (config.gtk) theme;
    };
  };
}
