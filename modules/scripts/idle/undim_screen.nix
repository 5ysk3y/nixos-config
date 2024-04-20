{ pkgs }:

pkgs.writeShellApplication {
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
    if [[ $BRIGHTNESS != .8 ]]
    then
        busctl call org.clightd.clightd /org/clightd/clightd/Backlight org.clightd.clightd.Backlight SetAll d\(bdu\)s 0.8 true 0 0 NULL
    fi
    wait
    done
}

undimScreen
hyprctl dispatch exec -- makoctl mode -s default
    '';
}
