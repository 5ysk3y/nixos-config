{ config, lib, ... }:
let
  inherit (config.features.home.waylandIdleInhibit) sinks;
in
{
  options.features.home.waylandIdleInhibit.sinks = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    example = [ "HDMI / External" ];
    description = "Audio sinks whose playback stops the screen idling; empty leaves the daemon's default.";
  };

  config.services.wayland-pipewire-idle-inhibit = {
    enable = true;
    systemdTarget = "graphical-session.target";
    settings = {
      verbosity = "INFO";
      media_minimum_duration = 10;
      idle_inhibitor = "wayland";
    }
    // lib.optionalAttrs (sinks != [ ]) {
      sink_whitelist = map (name: { inherit name; }) sinks;
    };
  };
}
