{
  config,
  vars,
  pkgs,
  ...
}:
{
  imports = [
    ./applications/waybar/waybar.nix
  ];

  home = {
    pointerCursor.enable = true;

    sessionVariables = {
      NIXOS_OZONE_WL = 1;
      QT_SCALE_FACTOR_ROUNDING_POLICY = "RoundPreferFloor";
    };

    packages = with pkgs; [
      fontconfig
      grimblast
      jq
      keyutils
      libnotify
      fastfetch
      wl-clipboard
    ];
  };

  # OpenRGB's device and profile settings (services.hardware.openrgb)
  xdg.configFile."OpenRGB/OpenRGB.json".text = builtins.readFile ./applications/openrgb/openrgb.json;

  programs = {
    git.settings.user.signingKey = "7D73BA8CF10F7F67";
  };

  features = {
    home = {
      hyprland = {
        luaConfig = ./applications/hypr/hyprland-host.lua;
        # Back to the desk lighting OpenRGB keeps (services.hardware.openrgb)
        resumeCommands = [ "openrgb -c 0000FF -m Direct" ];
      };

      # The clock and password field on the middle monitor, and the
      # three-monitor wallpaper across all three
      hyprlock = {
        primaryMonitor = "DP-1";
        wallpapers =
          let
            dir = "${config.xdg.configHome}/Wallpapers/3monitor";
          in
          {
            DP-1 = "${dir}/hackers_middle.png";
            DP-2 = "${dir}/hackers_left.png";
            HDMI-A-1 = "${dir}/hackers_right.png";
          };
      };

      media.hwdec = "nvdec";

      # The combined HDMI / external-speaker sink (system.nix's PipeWire)
      waylandIdleInhibit.sinks = [ "HDMI / External" ];

      mako = {
        output = "DP-1";
      };

      syncthing = {
        enable = true;

        folders.sync = {
          enable = true;
          path = vars.syncthingPath;
          type = "sendreceive";
          peers = [ "syncMaster" ];

          bootstrap = {
            enable = true;
          };
        };
      };
    };
  };
}
