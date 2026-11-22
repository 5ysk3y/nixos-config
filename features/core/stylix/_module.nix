{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Hack, the font the darwin overrides below give Ghostty and qutebrowser.
  # An override only names the font, so it has to be installed. gibson gets
  # it from the desktop's system fonts.
  home.packages = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin [ pkgs.hack-font ];

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
        # GUI apps. For qutebrowser it's the UI font, and its pages' default
        # font size is derived from it; gibson sets a smaller UI font itself.
        applications = 12;
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
            sizes.terminal = 10.875;
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
