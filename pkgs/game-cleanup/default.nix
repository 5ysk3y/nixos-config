{ pkgs }:
pkgs.writeShellApplication {
  name = "game_cleanup";
  runtimeInputs = [ pkgs.coreutils ];
  # Matched on each process's executable rather than grepping `ps aux`
  # lines, which also hit anything with "wine" or ".exe" in its arguments.
  # Every Wine/Proton process, the game's .exe included, runs the Wine
  # loader or wineserver. readlink fails on other users' processes, so
  # only the caller's own are touched.
  text = ''
    for exe in /proc/[0-9]*/exe; do
      target=$(readlink "$exe" 2>/dev/null) || continue
      name=''${target##*/}
      # nixpkgs wrappers exec .<name>-wrapped
      name=''${name#.}
      name=''${name%-wrapped}
      case "$name" in
        wine | wine64 | wine-preloader | wine64-preloader | wineserver | gamescope | gamescopereaper)
          pid=''${exe#/proc/}
          pid=''${pid%/exe}
          # The process may already be gone, taken down with wineserver
          kill -9 "$pid" 2>/dev/null || true
          ;;
      esac
    done
  '';
}
