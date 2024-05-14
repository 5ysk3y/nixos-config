{ config, lib, pkgs, hostname, ... }:

let

  dim_screen = pkgs.writeShellApplication {
    name = "dim_screen";
    runtimeInputs = with pkgs; [ dbus hyprland ];
    text = ''
getMonitorSerials() {
   busctl call org.clightd.clightd /org/clightd/clightd/Backlight2 org.clightd.clightd.Backlight2 Get  | grep -o '"[^"]\+"' | sed 's/"//g'
}

checkBrightness() {
     busctl call org.clightd.clightd /org/clightd/clightd/Backlight org.clightd.clightd.Backlight Get s "$1" | awk '{print $3}' | bc
}

dimScreen() {
    for s in $(getMonitorSerials); do
    BRIGHTNESS=$(checkBrightness "$s")
      while [[ $BRIGHTNESS != 0 ]]
      do
          busctl call org.clightd.clightd /org/clightd/clightd/Backlight org.clightd.clightd.Backlight SetAll d\(bdu\)s 0 true 0 0 NULL
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
   busctl call org.clightd.clightd /org/clightd/clightd/Backlight2 org.clightd.clightd.Backlight2 Get  | grep -o '"[^"]\+"' | sed 's/"//g'
}

checkBrightness() {
     busctl call org.clightd.clightd /org/clightd/clightd/Backlight org.clightd.clightd.Backlight Get s "$1" | awk '{print $3}' | bc
}

undimScreen() {
    for s in $(getMonitorSerials); do
    BRIGHTNESS=$(checkBrightness "$s")
    while [[ $BRIGHTNESS != .8 ]]
      do
          busctl call org.clightd.clightd /org/clightd/clightd/Backlight org.clightd.clightd.Backlight SetAll d\(bdu\)s 0.8 true 0 0 NULL
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
          settings = {
            general = {
              lock_cmd = "pidof hyprlock || hyprlock --immediate";
              after_sleep_cmd = "sleep 1; ${undim_screen.outPath}/bin/undim_screen; hyprctl --batch 'dispatch dpms on; dispatch exec makoctl mode -s default; dispatch exec openrgb -p ${config.xdg.configHome}/OpenRGB/MainBlue.orp'";
              ignore_dbus_inhibit = false;
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
