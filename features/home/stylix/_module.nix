{
  pkgs,
  lib,
  ...
}:

{
  stylix = {
    enable = true;
    autoEnable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-city-dark.yaml";
    polarity = "dark";

    cursor = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 22;
    };

    fonts = {
      monospace = {
        package = pkgs.noto-fonts;
        name = "Noto Sans Mono";
      };
      sizes = {
        terminal = 10; # already set
        applications = 12; # qutebrowser UI — bump if 12pt is still too small for you
        desktop = 13; # waybar — raise from the 10pt default
        popups = 12; # mako, rofi
      };
    };

    opacity.terminal = 0.87;

    targets = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      gtk.enable = true;
      kitty = {
        enable = true;
        fonts.override = {
          monospace = {
            package = pkgs.hack-font;
            name = "Hack";
          };
        };
      };
      rofi.enable = true;
      mako.enable = true;
      fuzzel.enable = false;
      hyprlock.enable = false;
      waybar.enable = false;
    };
  };
}
