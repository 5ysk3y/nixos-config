# Home Manager's apps on macOS. mac-app-util makes a "trampoline" for each
# one: a small launcher app in ~/Applications/Home Manager Trampolines,
# which Spotlight and Launchpad index (they skip the symlinks Home Manager
# makes).
#
# Its own activation step also runs sync-dock, which re-adds every Dock pin
# inside /nix/store on each switch, restarting the Dock each time and
# bringing it up over full-screen apps. The Dock pins are managed in
# _darwin.nix instead. So this makes the trampolines with mac-app-util's
# mktrampoline, and turns its own step off.
{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  mac-app-util = inputs.mac-app-util.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  imports = [ inputs.mac-app-util.homeManagerModules.default ];

  targets.darwin.mac-app-util.enable = false;

  # What mac-app-util's sync-trampolines does, without sync-dock: a fresh
  # trampoline for every app, and none for apps that have gone
  home.activation.appTrampolines = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    fromDir="$HOME/Applications/Home Manager Apps"
    toDir="$HOME/Applications/Home Manager Trampolines"
    run rm -rf "$toDir"
    if [ -d "$fromDir" ]; then
      run mkdir -p "$toDir"
      for app in "$fromDir"/*.app; do
        [ -e "$app" ] || continue
        run ${mac-app-util}/bin/mac-app-util mktrampoline "$app" "$toDir/$(basename "$app")"
      done
    fi
  '';
}
