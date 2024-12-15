{ config, lib, pkgs, hostname, vars, ... }:
let

    scripts = rec {
      check_rbw = (import ./scripts/check_rbw.nix {inherit pkgs;});
      current_song = (import ./scripts/current_song.nix {inherit pkgs;});
      mouse_battery = (import ./scripts/mouse_battery.nix {inherit pkgs;});
      mouse_colour = (import ./scripts/mouse_colour.nix {inherit pkgs;});
      music_panel = (import ./scripts/music_panel.nix {inherit pkgs current_song;});
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
            settings = {
              mainMonitor = {
                "layer" = "top";
                "position" = "top";
                "includes" = [ "${vars.nixos-config}/hosts/${hostname}/applications/waybar/waybar.conf" ];
                "height" = 30;

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
                    "hwmon-path" = "/sys/devices/pci0000:00/0000:00:18.3/hwmon/hwmon2/temp3_input";
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
                    "exec" = "${scripts.mouse_battery.outPath}/bin/mouse_battery";
                    "restart-interval" = 10;
                    "on-click" = "${scripts.mouse_colour.outPath}/bin/mouse_colour";
                };

                "custom/media" = {
                    "format" = " {}";
                    "escape" = "true";
                    "max-length" = 33;
                    "on-click" = "playerctl -s play-pause";
                    "on-click-right" = "playerctl -s stop";
                    "on-scroll-up" = "playerctl -s next";
                    "on-scroll-down" = "playerctl -s previous";
                    "exec" = "${scripts.music_panel.outPath}/bin/music_panel";
                    "restart-interval" = 10;
                };

                "pulseaudio" = {
                    "format" = "{icon} {volume}%";
                    "format-muted" = " Muted";
                    "ignored-sinks" = ["Starship/Matisse HD Audio Controller Analog Stereo" "Navi 21/23 HDMI/DP Audio Controller Digital Stereo (HDMI 5)" "Scarlett Solo USB Headphones / Line 1-2"];
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
                    background: @background-darker;
                    color: white;
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
                    background-color: @pink;
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
                    background-color: @yellow;
                    color: #000000;
                }

                #memory {
                    background-color: @purple;
                    color: #FFFFFF;
                }

                #disk {
                    background-color: #ff5555;
                }

                #pulseaudio {
                    background-color: @green;
                    color: #000000;
                }

                #custom-volume {
                    background-color: @background;
                    color: white;
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
