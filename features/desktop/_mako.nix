{
  config,
  lib,
  pkgs,
  vars,
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

  config = {
    # The sound played on notify (below), kept in Syncthing
    xdg.configFile."mako/notification.wav".source =
      config.lib.file.mkOutOfStoreSymlink "${vars.syncthingPath}/Files/nix/mako/notification.wav";

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

    # nixpkgs' mako routes D-Bus activation through mako.service
    # (SystemdService= in its D-Bus file), but ships the unit in
    # lib/systemd/user, which systemd's user search path never reads, and
    # home-manager's module doesn't link it. Without this unit, activation
    # fails with "unknown unit". Mirrors upstream contrib/systemd/mako.service.
    systemd.user.services.mako = {
      Unit = {
        Description = "Lightweight Wayland notification daemon";
        Documentation = "man:mako(1)";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "dbus";
        BusName = "org.freedesktop.Notifications";
        ExecCondition = "${pkgs.runtimeShell} -c '[ -n \"$WAYLAND_DISPLAY\" ]'";
        ExecStart = lib.getExe config.services.mako.package;
        ExecReload = "${lib.getExe' config.services.mako.package "makoctl"} reload";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
