{pkgs}:
pkgs.writeShellApplication {
  name = "game_cleanup";
  runtimeInputs = with pkgs; [gnugrep gawk util-linux];
  text = ''
    # shellcheck disable=SC2009
    for i in $(ps aux | grep -i "wine\|gamescope\|lutris-wrapper\|defunct\|\.exe" | grep -iv grep | awk '{print $2}'); do kill -9 "$i"; done
  '';
}
