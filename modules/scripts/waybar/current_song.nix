{ pkgs }:

pkgs.writeShellApplication {
    name = "current_song";
    runtimeInputs = with pkgs; [ playerctl coreutils-full gnused ];
    text = ''
set +o pipefail

PLAYER_STATUS=$(playerctl -s -p cider status 2>/dev/null | tail -n1)
ARTIST=$(playerctl -s -p cider metadata artist 2>/dev/null | sed 's/&/+/g')
TITLE=$(playerctl -s -p cider metadata title 2>/dev/null | sed 's/&/+/g')

if [[ $PLAYER_STATUS == "Paused" || $PLAYER_STATUS == "Playing" ]]; then
    echo "$ARTIST - $TITLE"
elif [[ $PLAYER_STATUS == "Stopped" ]]; then
    echo "No Music Playing"
else
   echo "Music Player Offline"
fi

    '';
}
