{
  config,
  pkgs,
  lib,
  ...
}:

{
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-city-dark.yaml";
    polarity = "dark";

    cursor = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 26;
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

    targets = lib.mkMerge [
      (lib.mkIf config.programs.qutebrowser.enable {
        qutebrowser = {
          fonts.override = {
            sansSerif = {
              package = pkgs.hack-font;
              name = "Hack";
            };
          };
        };
      })

      (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        ghostty = {
          colors.override = {
            base05 = "d8e2ec";
          };
          fonts.override = {
            monospace = {
              package = pkgs.hack-font;
              name = "Hack";
            };
            sizes.terminal = 11;
          };
        };
      })

      (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        kitty = {
          fonts.override = {
            monospace = {
              package = pkgs.hack-font;
              name = "Hack";
            };
          };
        };
        mako = {
          fonts.override = {
            sansSerif = {
              package = pkgs.tamzen;
              name = "Tamzen";
            };
          };
        };
        fuzzel.enable = false;
        hyprlock.enable = false;
        waybar.enable = false;
      })
    ];
  };
}
