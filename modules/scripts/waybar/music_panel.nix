{ pkgs }:

pkgs.writeShellApplication {
    name = "music_panel";
    runtimeInputs = with pkgs; [ playerctl zscroll ];
    text = ''
CURRENT_SONG="current_song"

zscroll -p " | " --delay 0.2 \
    --length 30 \
    --match-command "playerctl -s -p cider status 2>/dev/null" \
    --match-text "Playing" "--scroll 1" \
    --match-text "Paused" "--before-text ' ' --scroll 0" \
    --update-interval 1 \
    --update-check true $CURRENT_SONG &
wait
    '';
}
