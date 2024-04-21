{ pkgs }:

pkgs.writeShellApplication {
    name = "game_cleanup";
    runtimeInputs = with pkgs; [ gnugrep gawk util-linux ];
    text = ''
for i in $(pgrep -i 'wine|gamescope|lutris-wrapper|defunct'); do kill -9 "$i"; done
    '';
}
