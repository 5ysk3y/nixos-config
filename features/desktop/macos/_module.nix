# The macOS desktop: Dock, Finder, trackpad, appearance and window
# settings. Only settings that differ from Apple's defaults are listed, so a
# fresh install comes up as the Mac is set up now.
{ vars, ... }:
let
  # mac-app-util's stable copies of Home Manager's apps. The apps' own
  # paths are in the Nix store, and a Dock pin to one breaks once that
  # version is garbage-collected.
  hmApp = name: "${vars.homeDirectory}/Applications/Home Manager Trampolines/${name}.app";
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
        "/System/Applications/Siri AI.app"
        "/System/Applications/System Settings.app"
        (hmApp "Ghostty")
        (hmApp "qutebrowser")
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
