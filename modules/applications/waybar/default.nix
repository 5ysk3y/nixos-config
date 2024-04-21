{ config, lib, pkgs, hostname, inputs, ... }: {

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
            settings = {
              mainMonitor = {
                "layer" = "top";
                "position" = "top";
                "includes" = [ "${config.home.homeDirectory}/nix-config/hosts/${hostname}/applications/waybar/waybar.conf" ];
                "height" = 30;

                "modules-left" = ["hyprland/workspaces"];
                "modules-center" = ["hyprland/window"];
                "modules-right" = ["custom/rbw" "idle_inhibitor" "cpu" "memory" "disk" "temperature" "custom/steelseries" "custom/media" "pulseaudio"  "clock"];

                "hyprland/workspaces" = {
                "on-click" = "activate";
                };
                "hyprland/window" = {
                    "separate-outputs" = 1;
                };

                "custom/rbw" = {
                    "format" = "{}";
                    "escape" = "true";
                    "interval" = 30;
                    "exec" = "check_rbw";
                };
                "idle_inhibitor" = {
                    "format" = "{icon}";
                    "format-icons" = {
                        "activated" = "";
                        "deactivated" = "";
                    };
                };

                "cpu" = {
                    "format" = " {usage}%";
                    "interval" = 10;
                    "tooltip" = false;
                };

                "memory" = {
                    "format" = " {used:0.1f}G";
                };

                "disk" = {
                    "interval" = 10;
                    "format" = " {free}";
                    "path" = "/";
                };
                
                "temperature" = {
                    "thermal-zone" = 0;
                    "interval" = 2;
                    "hwmon-path" = "/sys/class/hwmon/hwmon3/temp1_input";
                    "critical-threshold" = 80;
                    "format-critical" = "{icon} {temperatureC}°C";
                    "format" = "{icon} {temperatureC}°C";
                    "format-icons" = ["" "" ""];
                };

                "custom/steelseries" = {
                    "format" = "  {icon}{} ";
                    "return-type" = "json";
                    "format-icons" = {
                        "100" =" ";
                        "75" =" ";
                        "50" = " ";
                        "25" = " ";
                        "0" = " ";
                        "charging" = "  ";
                        };
                    "exec" = "mouse_battery";
                    "restart-interval" = 10;
                    "on-click" = "mouse_colour";
                };

                "custom/media" = {
                    "format" = " {}";
                    "escape" = "true";
                    "max-length" = 40;
                    "on-click" = "playerctl -s play-pause";
                    "on-click-right" = "playerctl -s stop";
                    "on-scroll-up" = "playerctl -s next";
                    "on-scroll-down" = "playerctl -s previous";
                    "exec" = "music_panel";
                };

                "pulseaudio" = {
                    "format" = "{icon} {volume}%";
                    "format-muted" = " Muted";
                    "ignored-sinks" = ["Starship/Matisse HD Audio Controller Analog Stereo" "Navi 21/23 HDMI/DP Audio Controller Digital Stereo (HDMI 5)"];
                    "scroll-step" = 10;
                    "format-icons" = {
                        "default" = ["" "" ""];
                    };
                    "on-click" = "pwvucontrol";
                };

                "clock" = {
                    "tooltip-format" = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
                    "format" = " {:%H:%M}";
                };
              }; # End Main Monitor
            }; # End waybar.settings

            
            style = ''
                * {
                    /* `otf-font-awesome` is required to be installed for icons */
                    font-family: noto sans mono, FontAwesome6Free, SymbolsNerdFont;
                    font-size: 10px;
                    min-height: 0;
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
                    background-color: rgba(43, 48, 59, 0.9);
                    /* border-bottom: 3px solid rgba(100, 114, 125, 0.5); */
                    color: #ffffff;
                    transition-property: background-color;
                    transition-duration: .5s;
                    border-radius: 0px;
                }

                window#waybar.hidden {
                    opacity: 0.2;
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
                    padding: 0 5px;
                    background-color: transparent;
                    /* Use box-shadow instead of border so the text isn't offset */
                    box-shadow: inset 0 -3px transparent;
                    color: white;
                }

                #workspaces button:hover {
                    background: rgba(0, 0, 0, 0.2);
                }

                #workspaces button.active {
                    background-color: #44475a;
                    box-shadow: inset 0 -3px #ffffff;
                }

                #workspaces button.urgent {
                    background-color: #ff5555;
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
                    margin: 0 4px;
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
                    background-color: #64727D;
                }

                label {
                    all: unset;
                }

                label:focus {
                    background-color: #000000;
                }

                #custom-steelseries {
                    background-color: #50fa7b;
                    color: #000000;
                    padding: 5 5 5 0;
                    margin-left: 3px;
                    margin-right: 3px;
                }

                #cpu {
                    background-color: #50fa7b;
                    color: #000000;
                }

                #memory {
                    background-color: #6272a4;
                    color: #FFFFFF;
                }

                #disk {
                    background-color: #ff5555;
                }

                #pulseaudio {
                    background-color: #f1fa8c;
                    color: #000000;
                }

                #custom-volume {
                    background-color: #f1fa8c;
                    color: #000000;
                    padding: 5 6 5 6;
                    margin-left: 3px;
                    margin-right: 3px;
                }

                #pulseaudio.muted {
                    background-color: #90b1b1;
                    color: #2a5c45;
                }

                #custom-media {
                    background-color: #66cc99;
                    color: #2a5c45;
                    min-width: 100px;
                }

                #custom-media.custom-spotify {
                    background-color: #66cc99;
                }

                #custom-media.custom-vlc {
                    background-color: #ffa000;
                }

                #temperature {
                    background-color: #ffb86c;
                    color: #000000;
                }

                #temperature.critical {
                    background-color: #eb4d4b;
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
                    padding-left: 5;
                    padding-right: 5;
                }

                #custom-rbw.activated {
                    background-color: #44475a;
                    color: #FFF;
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
