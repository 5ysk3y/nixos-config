{ config, lib, pkgs, inputs, hostname, ... }:

let

  dim_screen = pkgs.writeShellApplication {
    name = "dim_screen";
    runtimeInputs = with pkgs; [ ddcutil hyprland ];
    text = ''
getMonitorSerials() {
   ddcutil detect | grep Serial | awk '{print $3}'
}

checkBrightness() {
     ddcutil --sn="$1" getvcp 0x10 | awk -F"," '{print $1}' | grep -o '[0-9]\+' | tail -n1
}

dimScreen() {
    for s in $(getMonitorSerials); do
    BRIGHTNESS=$(checkBrightness "$s")
      while [[ $BRIGHTNESS != "10" ]]
      do
          ddcutil --sn="$s" setvcp 0x10 10

          BRIGHTNESS=$(checkBrightness "$s")
      done
    wait
    done
}

dimScreen
hyprctl dispatch -- exec makoctl mode -s idle

    '';
  };

  undim_screen = pkgs.writeShellApplication {
    name = "undim_screen";
    runtimeInputs = with pkgs; [ dbus gnugrep hyprland ];
    text = ''
getMonitorSerials() {
   ddcutil detect | grep Serial | awk '{print $3}'
}

checkBrightness() {
     ddcutil --sn="$1" getvcp 0x10 | awk -F"," '{print $1}' | grep -o '[0-9]\+' | tail -n1
}


undimScreen() {
    for s in $(getMonitorSerials); do
    BRIGHTNESS=$(checkBrightness "$s")
      while [[ $BRIGHTNESS != "80" ]]
      do
          ddcutil --sn="$s" setvcp 0x10 80

          BRIGHTNESS=$(checkBrightness "$s")
      done
    wait
    done
}

undimScreen
hyprctl dispatch exec -- makoctl mode -s default
    '';
  };

in
{

  options = with lib; {
    applications = {
      hypr = {
        apps = {
          hypridle = mkEnableOption "Enabled Hypridle with custom configs";
        };
      };
    };
  };

  config = with lib; mkIf config.applications.hypr.enable (mkMerge [

    (mkIf (config.applications.hypr.apps.hypridle && hostname == "gibson") {
      services = {
        hypridle = with pkgs; {
          enable = true;
          package = inputs.hypridle.packages.${pkgs.system}.hypridle;
          settings = {
            general = {
              lock_cmd = "pidof hyprlock || hyprlock --immediate";
              after_sleep_cmd = "hyprctl --batch 'sleep 1; dispatch dpms on; dispatch exec makoctl mode -s default; dispatch exec openrgb -p ${config.xdg.configHome}/OpenRGB/MainBlue.orp; dispatch exec qpwgraph -ma ${config.xdg.configHome}/qpwgraph/default.qpwgraph'; ${undim_screen.outPath}/bin/undim_screen;";
              ignore_dbus_inhibit = false;
              ignore_systemd_inhibit = false;
            };

            listener = [
              {
                timeout = 300;
                on-timeout = "${dim_screen.outPath}/bin/dim_screen";
                on-resume = "${undim_screen.outPath}/bin/undim_screen";
              }
              {
                timeout = 360;
                on-timeout = "loginctl lock-session";
              }
              {
                timeout = 600;
                on-timeout = "sleep 1 && hyprctl dispatch dpms off";
                on-resume = "sleep 1 && hyprctl dispatch dpms on";
              }
              {
                timeout = 900;
                on-timeout = "systemctl hibernate";
              }
            ];
          };
        };
      };
    })
  ]); # End mkMerge
}
