{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  services.mako = {
    enable = true;
    settings = {
      output = "DP-1";
      background-color = "#282A36";
      text-color = "#FFFFFF";
      padding = "10";
      font = "Tamzen 12";
      layer = "overlay";
      anchor = "top-right";
      margin = "11";
      default-timeout = 20000;
      border-size = 1;
      border-radius = 5;
      width = 400;
      height = 170;
      max-icon-size = 32;

      "urgency=low" = {
        border-color = "#BD93F9";
      };

      "urgency=normal" = {
        border-color = "#BD93F9";
        on-notify = "exec ${pkgs.vlc}/bin/cvlc --play-and-exit ${config.xdg.configHome}/mako/notification.wav";
      };

      "urgency=high" = {
        border-color = "#FF5555";
        on-notify = "exec ${pkgs.vlc}/bin/cvlc --play-and-exit ${config.xdg.configHome}/mako/notification.wav";
      };

      "mode=idle" = {
        default-timeout = 0;
        ignore-timeout = 1;
      };
    };
  };
}
