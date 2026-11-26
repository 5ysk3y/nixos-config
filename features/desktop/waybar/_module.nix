{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  # Used by custom/media, and checked against the binary at build time.
  scrollMprisArgs = [
    "--freeze"
    "-b"
    "vlc"
    "--format"
    # Only the [scroll] block scrolls; the icons stay fixed in front.
    "{player_icon} {status_icon} [scroll]{title} - {artist}[/scroll]"
  ];
  scripts = {
    waybar = import ./_scripts {
      inherit pkgs;
      rbw = config.programs.rbw.package;
    };
    scroll_mpris = import ./_scripts/scroll-mpris {
      inherit pkgs inputs;
      args = scrollMprisArgs;
    };
  };
in
{
  imports = [ ./_scaled-outputs.nix ];

  # The single producer for custom/steelseries (see _scripts). A
  # long-running loop rather than a timer, so the journal doesn't get two
  # lines every 10 seconds.
  systemd.user.services.mouse-battery = {
    Unit = {
      Description = "Mouse battery reading for Waybar's custom/steelseries";
      PartOf = config.programs.waybar.systemd.targets;
      After = config.programs.waybar.systemd.targets;
    };
    Service = {
      ExecStart = lib.getExe scripts.waybar.mouse_battery_producer;
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = config.programs.waybar.systemd.targets;
  };

  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings = {
      mainBar = with lib; {
        layer = "top";
        position = "top";
        height = 40;

        modules-left = mkDefault [ "hyprland/workspaces" ];
        modules-center = mkDefault [ "hyprland/window" ];
        modules-right = mkDefault [
          "cpu"
          "memory"
          "disk"
          "clock"
        ];

        "hyprland/workspaces" = {
          on-click = "activate";
        };

        "hyprland/window" = {
          separate-outputs = 1;
          # One fixed, centred width on every output: long titles end in
          # "…" and short ones sit in the middle.
          min-length = 60;
          max-length = 60;
          align = 0.5;
          # The underline hugs the title, not the fixed slot. GTK's CSS
          # underline can't take its own colour or a gap, so it's Pango's:
          # "low" sits below the descenders, in a dimmed style.css cyan.
          format = "<span underline='low' underline_color='#04808a'>{title}</span>";
        };

        "group/quickHacks" = {
          orientation = "inherit";
          drawer = {
            "children-class" = "sub-icons";
          };
          modules = [
            "custom/rbw"
            "idle_inhibitor"
          ];
        };

        "custom/rbw" =
          let
            rbw = lib.getExe config.programs.rbw.package;
          in
          {
            format = "{}";
            escape = true;
            interval = 30;
            # qute-rbw sends this after unlocking, so the icon needn't wait
            signal = 8;
            exec = "${scripts.waybar.check_rbw.outPath}/bin/check_rbw";
            on-click = "${rbw} unlock; pkill -RTMIN+8 waybar";
            on-click-right = "${rbw} lock; pkill -RTMIN+8 waybar";
          };

        idle_inhibitor = {
          format = "{icon}";
          "format-icons" = {
            activated = "󰈈";
            deactivated = "󰈉";
          };
        };

        # The icon <span> colours below mirror style.css's palette:
        # cyan #00f0ff, yellow #fcee0a, orange #ff9e00, red #ff003c (alerts),
        # violet #b967ff, magenta #ff2a6d, green #39ff14.
        cpu = {
          format = "<span foreground='#00f0ff'></span> {usage}%";
          interval = 10;
          tooltip = false;
        };

        memory = {
          format = "<span foreground='#b967ff'></span> {used:0.1f}G";
        };

        disk = {
          interval = 10;
          format = " {free}";
          path = "/";
        };

        temperature = {
          "critical-threshold" = 80;
          "format-critical" = "<span foreground='#ff003c'>{icon}</span> {temperatureC}󰔄";
          format = "<span foreground='#ff9e00'>{icon}</span> {temperatureC}󰔄";
          "format-icons" = [
            ""
            ""
            ""
          ];
        };

        "custom/steelseries" = {
          format = "  {icon}{text} ";
          "return-type" = "json";
          "format-icons" = {
            "100" = "<span foreground='#39ff14'>  </span>";
            "75" = "<span foreground='#39ff14'>  </span>";
            "50" = "<span foreground='#fcee0a'>  </span>";
            "25" = "<span foreground='#ff9e00'>  </span>";
            "0" = "<span foreground='#ff003c'>  </span>";
            charging = "<span foreground='#00f0ff'>  </span>";
          };
          # Only reads the file mouse-battery.service writes. That service
          # sends this signal, so every bar's copy refreshes at once.
          exec = "${scripts.waybar.mouse_battery.outPath}/bin/mouse_battery";
          signal = 9;
          "on-click" = "${scripts.waybar.mouse_colour.outPath}/bin/mouse_colour";
        };

        "custom/media" = {
          "return-type" = "json";
          escape = true;
          "on-click" = "playerctl -s play-pause";
          "on-click-right" = "playerctl -s stop";
          "on-scroll-up" = "playerctl -s next";
          "on-scroll-down" = "playerctl -s previous";
          exec = "${scripts.scroll_mpris.outPath}/bin/ScrollMPRIS ${lib.escapeShellArgs scrollMprisArgs}";
        };

        pulseaudio = {
          format = "<span foreground='#ff2a6d'>{icon}</span>{volume}%";
          "format-muted" = "<span foreground='#fcee0a'>  </span>Muted";
          "scroll-step" = 10;
          "format-icons" = [
            " "
            " "
            " "
          ];
          "on-click" = "pavucontrol";
        };

        clock = {
          "tooltip-format" = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          format = " {:%H:%M}";
        };
      };
    };

    # A file rather than a string, so nix run .#waybar-preview can run a
    # second bar from a checkout's copy and reload it on every save.
    style = ./style.css;
  };

  # The theme's text and clock faces (see style.css)
  home.packages = [ (import ./_theme-fonts.nix pkgs) ];
}
