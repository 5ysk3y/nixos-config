{ pkgs, current_song }:

pkgs.writeShellApplication {
    name = "music_panel";
    runtimeInputs = with pkgs; [ playerctl zscroll ];
    text = ''

get_player_icon() {
    PLAYER=$(playerctl metadata --format "{{playerName}}")
    case $PLAYER in
        chromium)
            echo " "
            ;;
        *)
            echo " "
            ;;
        esac
}

zscroll -p " | " --delay 0.2 \
    --length 30 \
    --match-command "playerctl -s status 2>/dev/null" \
    --match-text "Playing" "--before-text '$(get_player_icon)' --scroll 1" \
    --match-text "Paused" "--before-text '$(get_player_icon) ' --scroll 0" \
    --before-text "$(playerctl metadata --format '{{ playerName }}' 2>/dev/null | awk '{if ($1=="cider") print " "; else if ($1=="chromium") print " "; else print " "}')" \
    --update-interval 1 \
    --update-check true ${current_song}/bin/current_song
    '';
}

