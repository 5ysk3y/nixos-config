{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.home.mako;
in
{
  options.features.home.mako = {
    output = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Preferred output name for mako notifications.";
    };
  };

  config = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    services.mako = {
      enable = true;
      settings = {
        padding = "10";
        layer = "overlay";
        anchor = "top-right";
        margin = "11";
        default-timeout = 20000;
        border-size = 1;
        border-radius = 5;
        width = 400;
        height = 170;
        max-icon-size = 32;

        "urgency=normal" = {
          on-notify = "exec ${pkgs.vlc}/bin/cvlc --play-and-exit ${config.xdg.configHome}/mako/notification.wav";
        };

        "urgency=critical" = {
          on-notify = "exec ${pkgs.vlc}/bin/cvlc --play-and-exit ${config.xdg.configHome}/mako/notification.wav";
        };

        "mode=idle" = {
          default-timeout = 0;
          ignore-timeout = 1;
        };
      }
      // lib.optionalAttrs (cfg.output != null) {
        inherit (cfg) output;
      };
    };
  };
}
