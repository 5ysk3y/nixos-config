{ pkgs }:

pkgs.writeShellScriptBin "qute-rbw" ''
    ${pkgs.rbw}/bin/rbw unlocked > /dev/null 2>&1
    RC="$?"

    if [[ "$RC" -eq 1 ]]; then
        ${pkgs.kitty}/bin/kitty -T "rbw password prompt" ${pkgs.rbw}/bin/rbw unlock > /dev/null 2>&1 && ${pkgs.hyprland}/bin/hyprctl dispatch focuswindow qutebrowser && ${pkgs.rofi-rbw-wayland}/bin/rofi-rbw
    else
        ${pkgs.rofi-rbw-wayland}/bin/rofi-rbw
    fi
''
