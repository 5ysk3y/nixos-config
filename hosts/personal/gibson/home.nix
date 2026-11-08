{
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
      rivalcfg
      wl-clipboard
      wtype
    ];
  };

  programs = {
    git.settings.user.signingKey = "7D73BA8CF10F7F67";
  };

  features = {
    home = {
      hyprland.luaConfig = ./applications/hypr/hyprland-host.lua;

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
