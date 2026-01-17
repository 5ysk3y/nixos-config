{
  config,
  lib,
  pkgs,
  hostname,
  vars,
  ...
}:
let
  scripts = rec {
    waybar = import ./scripts { inherit pkgs; };
    scroll_mpris = import ./scripts/scroll-mpris { inherit pkgs; };
  };
  waybarConfig = vars.flakeSource + "/hosts/${hostname}/applications/waybar/waybar.conf";
in
{
  options = with lib; {
    applications = {
      waybar = mkEnableOption "Enable the Waybar application with custom config";
    };
  };

  config =
    with lib;
    mkIf config.applications.waybar {
      programs = {
        waybar = {
          enable = true;
          systemd = {
            enable = true;
          };
          settings = mkMerge [
            (mkIf (hostname == "gibson") {
              mainBar = {
                "layer" = "top";
                "position" = "top";
                "includes" = [ waybarConfig ];
                "height" = 40;

                "modules-left" = [ "hyprland/workspaces" ];
                "modules-center" = [ "hyprland/window" ];
                "modules-right" = [
                  "group/quickHacks"
                  "cpu"
                  "memory"
                  "temperature"
                  "custom/steelseries"
                  "custom/media"
                  "pulseaudio"
                  "clock"
                ];

                "hyprland/workspaces" = {
                  "on-click" = "activate";
                };
                "hyprland/window" = {
                  "separate-outputs" = 1;
                };

                "group/quickHacks" = {
                  "orientation" = "inherit";
                  "drawer" = {
                    "children-class" = "sub-icons";
                  };
                  "modules" = [
                    "custom/rbw"
                    "idle_inhibitor"
                  ];
                };

                "custom/rbw" = {
                  "format" = "{}";
                  "escape" = "true";
                  "interval" = 30;
                  "exec" = "${scripts.waybar.check_rbw.outPath}/bin/check_rbw";
                };
                "idle_inhibitor" = {
                  "format" = "{icon}";
                  "format-icons" = {
                    "activated" = "󰈈";
                    "deactivated" = "󰈉";
                  };
                };

                "cpu" = {
                  "format" = " {usage}%";
                  "interval" = 10;
                  "tooltip" = false;
                };

                "memory" = {
                  "format" = " {used:0.1f}G";
                };

                "disk" = {
                  "interval" = 10;
                  "format" = " {free}";
                  "path" = "/";
                };

                "temperature" = {
                  "hwmon-path-abs" = "/sys/devices/pci0000:00/0000:00:18.3/hwmon/";
                  "input-filename" = "temp1_input";
                  "critical-threshold" = 80;
                  "format-critical" = "{icon} {temperatureC}󰔄";
                  "format" = "{icon} {temperatureC}󰔄";
                  "format-icons" = [
                    ""
                    ""
                    ""
                  ];
                };

                "custom/steelseries" = {
                  "format" = "  {icon}{text} ";
                  "return-type" = "json";
                  "format-icons" = {
                    "100" = "  ";
                    "75" = "  ";
                    "50" = "  ";
                    "25" = "  ";
                    "0" = "  ";
                    "charging" = "  ";
                  };
                  "exec" = "${scripts.waybar.mouse_battery.outPath}/bin/mouse_battery";
                  "restart-interval" = 10;
                  "on-click" = "${scripts.waybar.mouse_colour.outPath}/bin/mouse_colour";
                };

                "custom/media" = {
                  "return-type" = "json";
                  "escape" = "true";
                  "on-click" = "playerctl -s play-pause";
                  "on-click-right" = "playerctl -s stop";
                  "on-scroll-up" = "playerctl -s next";
                  "on-scroll-down" = "playerctl -s previous";
                  "exec" =
                    "${scripts.scroll_mpris.outPath}/bin/ScrollMPRIS --freeze -b vlc --format '{title} - {artist}'";
                };

                "pulseaudio" = {
                  "format" = "{icon}{volume}%";
                  "format-muted" = "  Muted";
                  "scroll-step" = 10;
                  "format-icons" = [
                    " "
                    " "
                    " "
                  ];
                  "on-click" = "pwvucontrol";
                  "ignored-sinks" = [
                    "Starship/Matisse HD Audio Controller Analog Stereo"
                    "Navi 21/23 HDMI/DP Audio Controller Digital Stereo (HDMI 5)"
                  ];
                };

                "clock" = {
                  "tooltip-format" = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
                  "format" = " {:%H:%M}";
                };
              }; # End mainBar
            })
          ]; # End waybar.settings

          style = ''
            @define-color bg0 rgba(8, 10, 18, 0.55);
            @define-color panel rgba(12, 16, 28, 0.68);
            @define-color panel2 rgba(16, 20, 34, 0.72);

            @define-color fg #e6e6e6;
            @define-color fgDim rgba(230, 230, 230, 0.75);

            @define-color neonCyan rgba(120, 255, 240, 0.85);
            @define-color neonPink rgba(255, 0, 200, 0.72);
            @define-color neonPurple rgba(180, 120, 255, 0.70);
            @define-color warn rgba(255, 190, 80, 0.85);
            @define-color crit rgba(255, 70, 70, 0.85);

            * {
              font-family: noto sans mono, FontAwesome6Free, SymbolsNerdFont;
              font-size: 10px;
              min-height: 0;
              border: none;
              border-radius: 0;
            }

            window#waybar {
              background-image: repeating-linear-gradient(
                to bottom,
                rgba(255, 255, 255, 0.03),
                rgba(255, 255, 255, 0.03) 1px,
                rgba(0, 0, 0, 0.0) 3px,
                rgba(0, 0, 0, 0.0) 6px
              );
              background-color: @bg0;
              color: @fg;
              transition-property: background-color;
              transition-duration: 0.25s;
            }

            window#waybar.hidden {
              opacity: 0.5;
            }

            /* window title, keep it minimal and “HUD” */
            #window {
              padding-left: 10px;
              padding-right: 10px;
              background: transparent;
              border-bottom: 2px solid rgba(180, 120, 255, 0.45);
              color: @fgDim;
            }

            /* Base “chip” style for modules */
            #clock,
            #cpu,
            #memory,
            #disk,
            #temperature,
            #pulseaudio,
            #custom-media,
            #custom-rbw,
            #idle_inhibitor,
            #custom-steelseries,
            #mode {
              padding: 6px 10px;
              margin: 6px 4px;
              background: @panel;
              border: 1px solid rgba(120, 255, 240, 0.14);
              border-radius: 12px;
              color: @fg;
              box-shadow:
                0 0 0 1px rgba(255, 0, 200, 0.06) inset,
                0 6px 16px rgba(0, 0, 0, 0.35);
            }

            /* Workspace strip stays “floating” */
            #workspaces,
            #window {
              background-color: transparent;
            }

            /* Workspaces, cyber pills */
            #workspaces button {
              all: initial;
              font-family: noto sans mono, FontAwesome6Free, SymbolsNerdFont;
              font-size: 10px;

              min-width: 0;
              padding: 6px 10px;
              margin: 6px 3px;

              border-radius: 12px;
              background: @panel;
              color: @fgDim;

              border: 1px solid rgba(120, 255, 240, 0.12);
              box-shadow: 0 6px 16px rgba(0, 0, 0, 0.30);
              transition: all 120ms ease;
            }

            #workspaces button:hover {
              color: @fg;
              border-color: rgba(120, 255, 240, 0.35);
              box-shadow: 0 0 18px rgba(120, 255, 240, 0.18);
            }

            #workspaces button.active {
              color: rgba(8, 10, 18, 0.90);
              background: rgba(120, 255, 240, 0.92);
              border-color: rgba(120, 255, 240, 0.65);
              box-shadow:
                0 0 0 1px rgba(255, 0, 200, 0.22) inset,
                0 0 24px rgba(120, 255, 240, 0.26);
            }

            #workspaces button.urgent {
              border-color: @crit;
              box-shadow: 0 0 20px rgba(255, 70, 70, 0.25);
            }

            /* margin fixes you already had */
            .modules-left > widget:first-child > #workspaces { margin-left: 0; }
            .modules-right > widget:last-child > #workspaces { margin-right: 0; }

            label { all: unset; }
            label:focus { background-color: #000000; }

            /* Right side: give each module a neon “edge accent” instead of full block color */
            #cpu { border-left: 3px solid rgba(120, 255, 240, 0.55); }
            #memory { border-left: 3px solid rgba(180, 120, 255, 0.55); }
            #temperature { border-left: 3px solid rgba(255, 190, 80, 0.55); }
            #pulseaudio { border-left: 3px solid rgba(255, 0, 200, 0.45); }
            #clock { border-left: 3px solid rgba(180, 120, 255, 0.45); }
            #custom-media { border-left: 3px solid rgba(120, 255, 240, 0.45); }
            #custom-steelseries { border-left: 3px solid rgba(255, 0, 200, 0.45); }
            #idle_inhibitor { border-left: 3px solid rgba(180, 120, 255, 0.45); }
            #custom-rbw { border-left: 3px solid rgba(120, 255, 240, 0.35); }

            /* Preserve your media min width */
            #custom-media {
              min-width: 140px;
            }

            /* Temperature and audio state handling */
            #temperature.critical {
              border-left: 3px solid @crit;
              box-shadow: 0 0 24px rgba(255, 70, 70, 0.18);
            }

            #pulseaudio.muted {
              border-left: 3px solid @warn;
              color: @fgDim;
            }

            /* Idle inhibitor state */
            #idle_inhibitor.activated {
              border-left: 3px solid @neonPink;
              box-shadow: 0 0 18px rgba(255, 0, 200, 0.18);
            }

            /* Your steelseries battery states, keep them but cyber */
            #custom-steelseries.fine {
              border-left: 3px solid rgba(120, 255, 240, 0.60);
            }

            #custom-steelseries.nearlylowbat {
              border-left: 3px solid @warn;
              box-shadow: 0 0 18px rgba(255, 190, 80, 0.15);
            }

            @keyframes blink {
              to {
                border-left-color: rgba(255, 70, 70, 1.0);
                box-shadow: 0 0 22px rgba(255, 70, 70, 0.25);
              }
            }

            #custom-steelseries.lowbat:not(.fine) {
              border-left: 3px solid @crit;
              animation-name: blink;
              animation-duration: 1.0s;
              animation-timing-function: ease-in-out;
              animation-iteration-count: infinite;
              animation-direction: alternate;
            }

            /* Drawer children, your "sub-icons" class */
            .sub-icons > * {
              margin-left: 6px;
            }

            /* Tooltips, match the bar */
            tooltip {
              background: rgba(8, 10, 18, 0.92);
              border: 1px solid rgba(120, 255, 240, 0.25);
              border-radius: 12px;
              box-shadow: 0 12px 22px rgba(0, 0, 0, 0.45);
            }

            tooltip label {
              color: @fg;
              padding: 6px 8px;
            }
          ''; # End waybar.style
        }; # End waybar
      }; # End programs
    };
}
