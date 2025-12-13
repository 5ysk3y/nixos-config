{pkgs}:
pkgs.writeShellApplication {
  name = "dim_screen";
  runtimeInputs = with pkgs; [ddcutil hyprland gnused gnugrep gawk];
  text = ''
    checkBrightness() {
        ddcutil --bus="$1" getvcp 10 | awk '{print $9}' | sed 's/,//g'
    }
    dimScreen() {
        for s in $(ddcutil detect | grep i2c | awk -F- '{ print $2 }'); do
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
