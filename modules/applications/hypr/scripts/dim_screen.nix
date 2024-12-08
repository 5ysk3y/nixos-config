{ pkgs }:

pkgs.writeShellApplication {
    name = "undim_screen";
    runtimeInputs = with pkgs; [ ddcutil hyprland gnused gawk ];
    text = ''
checkBrightness() {
    ddcutil --bus="$1" getvcp 10 | awk '{print $9}' | sed 's/,//g'
}
dimScreen() {
    for s in 8 9 10; do
    BRIGHTNESS=$(checkBrightness "$s")
      while [[ $BRIGHTNESS != "10" ]]
      do
          ddcutil --bus="$s" setvcp 10 10
          BRIGHTNESS=$(checkBrightness "$s")
      done
    wait
    done
}

dimScreen
hyprctl dispatch -- exec makoctl mode -s idle

    '';
}
