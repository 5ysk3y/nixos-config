{ config, lib, pkgs, hostname, vars, ... }:
let

    scripts = rec {
      check_rbw = (import ./scripts/check_rbw.nix {inherit pkgs;});
      mouse_battery = (import ./scripts/mouse_battery.nix {inherit pkgs;});
      mouse_colour = (import ./scripts/mouse_colour.nix {inherit pkgs;});
      scroll_mpris = (import ./scripts/scroll-mpris {inherit pkgs;});
    };

in

{

    options = with lib; {
      applications = {
        waybar = mkEnableOption "Enable the Waybar application with custom config";
      };
    };

    config = with lib; mkIf config.applications.waybar {
      programs = {
        waybar = {
          enable = true;
            systemd = {
              enable = true;
            };
            settings = (mkMerge [
                (mkIf (hostname == "gibson") {
                mainBar = {
                "layer" = "top";
                "position" = "top";
                "includes" = [ "${vars.nixos-config}/hosts/${hostname}/applications/waybar/waybar.conf" ];
                "height" = 40;

                "modules-left" = ["hyprland/workspaces"];
                "modules-center" = ["hyprland/window"];
                "modules-right" = [ "group/quickHacks" "cpu" "memory" "temperature" "custom/steelseries" "custom/media" "pulseaudio"  "clock"];

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
                    "modules" = [ "custom/rbw" "idle_inhibitor" ];
                };

                "custom/rbw" = {
                    "format" = "{}";
                    "escape" = "true";
                    "interval" = 30;
                    "exec" = "${scripts.check_rbw.outPath}/bin/check_rbw";
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
                    "hwmon-path" = "/sys/class/hwmon/hwmon3/temp3_input";
                    "critical-threshold" = 80;
                    "format-critical" = "{icon} {temperatureC}󰔄";
                    "format" = "{icon} {temperatureC}󰔄";
                    "format-icons" = ["" "" ""];
                };

                "custom/steelseries" = {
                    "format" = "  {icon}{text} ";
                    "return-type" = "json";
                    "format-icons" = {
                        "100" =" ";
                        "75" =" ";
                        "50" = " ";
                        "25" = " ";
                        "0" = " ";
                        "charging" = "  ";
                        };
                    "exec" = "${scripts.mouse_battery.outPath}/bin/mouse_battery";
                    "restart-interval" = 10;
                    "on-click" = "${scripts.mouse_colour.outPath}/bin/mouse_colour";
                };

                "custom/media" = {
                    "return-type" = "json";
                    "escape" = "true";
                    "on-click" = "playerctl -s play-pause";
                    "on-click-right" = "playerctl -s stop";
                    "on-scroll-up" = "playerctl -s next";
                    "on-scroll-down" = "playerctl -s previous";
                    "exec" = "${scripts.scroll_mpris.outPath}/bin/ScrollMPRIS -s 50 -w 30";
                };

                "pulseaudio" = {
                    "format" = "{icon}{volume}%";
                    "format-muted" = "  Muted";
                    "scroll-step" = 10;
                    "format-icons" = [" " " " " "];
                    "on-click" = "pwvucontrol";
                    "ignored-sinks" = ["Starship/Matisse HD Audio Controller Analog Stereo" "Navi 21/23 HDMI/DP Audio Controller Digital Stereo (HDMI 5)"];
                };

                "clock" = {
                    "tooltip-format" = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
                    "format" = " {:%H:%M}";
                };
              }; # End mainBar
            })
            ]); # End waybar.settings

            
            style = ''
                @define-color background-darker rgba(30, 31, 41, 230);
                @define-color background #282a36;
                @define-color selection #44475a;
                @define-color foreground #f8f8f2;
                @define-color comment #6272a4;
                @define-color cyan #8be9fd;
                @define-color green #50fa7b;
                @define-color orange #ffb86c;
                @define-color pink #ff79c6;
                @define-color purple #bd93f9;
                @define-color red #ff5555;
                @define-color yellow #f1fa8c;
                * {
                    /* `otf-font-awesome` is required to be installed for icons */
                    font-family: noto sans mono, FontAwesome6Free, SymbolsNerdFont;
                    font-size: 10px;
                    min-height: 0;
                    border: none;
                    border-radius: 0;
                }

                #window {
                    padding-left: 10px;
                    padding-right: 10px;
                    border-bottom: 2px solid #bd93f9;
                }


                window.DP-1 * {
                    font-size: 10px;
                }

                window#waybar {
                    transition-property: background-color;
                    transition-duration: 0.5s;
                }

                window#waybar.hidden {
                    opacity: 0.5;
                }

                /*
                window#waybar.empty {
                    background-color: transparent;
                }
                window#waybar.solo {
                    background-color: #FFFFFF;
                }
                */

                #workspaces button {
                    all: initial;
                    /* Remove GTK theme values (waybar #1351) */
                    min-width: 0;
                    /* Fix weird spacing in materia (waybar #450) */
                    box-shadow: inset 0 -3px transparent;
                    /* Use box-shadow instead of border so the text isn't offset */
                    padding: 6px 8px;
                    margin: 6px 3px;
                    border-radius: 4px;
                    background-color: #1e1e2e;
                    color: #cdd6f4;
                }

                #workspaces button:hover {
                    box-shadow: inherit;
                    text-shadow: inherit;
                    color: #1e1e2e;
                    background-color: #cdd6f4;
                }

                #workspaces button.active {
                    color: #1e1e2e;
                    background-color: #cdd6f4;
                }

                #workspaces button.urgent {
                    background-color: #f38ba8;
                }

                #mode {
                    background-color: #64727D;
                    border-bottom: 3px solid #ffffff;
                }

                #clock,
                #battery,
                #cpu,
                #memory,
                #disk,
                #temperature,
                #pulseaudio,
                #custom-media,
                #custom-rbw
                #mode,
                #idle_inhibitor {
                    padding: 0 10px;
                    margin: 0 4px;
                    color: #ffffff;
                }

                #window,
                #workspaces {
                    background-color: transparent;
                }

                /* If workspaces is the leftmost module, omit left margin */
                .modules-left > widget:first-child > #workspaces {
                    margin-left: 0;
                }

                /* If workspaces is the rightmost module, omit right margin */
                .modules-right > widget:last-child > #workspaces {
                    margin-right: 0;
                }

                #clock {
                    background-color: @pink;
                }

                label {
                    all: unset;
                }

                label:focus {
                    background-color: #000000;
                }

                #custom-steelseries {
                    background-color: @selection;
                    color: #FFFFFF;
                    padding: 5px 5px 5px 0px;
                    margin-left: 3px;
                    margin-right: 3px;
                }

                #cpu {
                    background-color: @cyan;
                    color: #000000;
                }

                #memory {
                    background-color: @purple;
                    color: #FFFFFF;
                }

                #pulseaudio {
                    background-color: @green;
                    color: #000000;
                }

                #custom-volume {
                    background-color: @background;
                    color: white;
                    padding: 5px 6px 5px 6px;
                    margin-left: 3px;
                    margin-right: 3px;
                }

                #pulseaudio.muted {
                    background-color: #90b1b1;
                    color: #2a5c45;
                }

                #custom-media {
                    background-color: @yellow;
                    color: #2a5c45;
                    min-width: 100px;
                }

                #temperature {
                    background-color: @orange;
                    color: #000000;
                }

                #temperature.critical {
                    background-color: @red;
                }

                #idle_inhibitor {
                    color: #FFF;
                }

                #idle_inhibitor.activated {
                    background-color: #44475a;
                    color: #FFF;
                }

                #custom-rbw {
                    color: #FFF;
                    padding: 0 10px;
                    color: #ffffff;
                }

                #language {
                    background: #00b093;
                    color: #740864;
                    padding: 0 5px;
                    margin: 0 5px;
                    min-width: 16px;
                }

                #custom-steelseries.fine {
                    background-color: yellowgreen;
                    color: black;
                }

                #custom-steelseries.nearlylowbat {
                    background-color: firebrick;
                    color: white;
                }

                @keyframes blink {
                    to {
                        background-color: red;
                        color: white;
                    }
                }

                #custom-steelseries.lowbat:not(.fine) {
                    background: red;
                    color: red;
                    animation-name: blink;
                    animation-duration: 1.2s;
                    animation-timing-function: ease-in-out;
                    animation-iteration-count: infinite;
                    animation-direction: alternate;
                }
                ''; # End waybar.style

            }; # End waybar

        }; # End programs
    };
}
