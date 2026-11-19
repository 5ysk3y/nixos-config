# The macOS desktop: Dock, Finder, trackpad, appearance and window
# settings. Only settings that differ from Apple's defaults are listed, so a
# fresh install comes up as the Mac is set up now.
{ config, vars, ... }:
let
  # A Home Manager app, at the store path its current package installs.
  # Every switch rewrites the Dock with these paths, so a pin never points
  # at a garbage-collected version. mac-app-util's trampolines can't be
  # pinned instead: each one is a launcher that starts the real app as a
  # second Dock icon, and it shows a generic icon.
  hmApp =
    program: name:
    "${
      config.home-manager.users.${vars.username}.programs.${program}.package
    }/Applications/${name}.app";
in
{
  system.defaults = {
    dock = {
      tilesize = 79;
      show-recents = false;
      # Bottom-right hot corner: Quick Note
      wvous-br-corner = 14;

      persistent-apps = map (app: { inherit app; }) [
        "/System/Applications/Apps.app"
        "/System/Applications/Messages.app"
        "/System/Applications/Mail.app"
        "/System/Applications/System Settings.app"
        (hmApp "ghostty" "Ghostty")
        (hmApp "qutebrowser" "qutebrowser")
        "/Applications/Claude.app"
      ];
    };

    finder = {
      # List view
      FXPreferredViewStyle = "Nlsv";
    };

    # Tap to click, and three-finger drag
    trackpad = {
      Clicking = true;
      TrackpadThreeFingerDrag = true;
    };

    NSGlobalDomain.AppleInterfaceStyle = "Dark";

    menuExtraClock = {
      ShowAMPM = true;
      ShowDayOfWeek = true;
    };

    WindowManager = {
      # Hide desktop items while Stage Manager is on
      HideDesktop = true;
      # No gaps between tiled windows
      EnableTiledWindowMargins = false;
    };

    CustomUserPreferences.NSGlobalDomain = {
      # Blue accent and dark app icons
      AppleAccentColor = 4;
      AppleIconAppearanceTheme = "RegularDark";
    };
  };
}
