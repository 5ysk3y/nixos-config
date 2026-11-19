# The macOS desktop: Dock, Finder, trackpad, appearance and window
# settings. Only settings that differ from Apple's defaults are listed, so a
# fresh install comes up as the Mac is set up now.
{
  config,
  lib,
  pkgs,
  vars,
  ...
}:
let
  # A Home Manager app, at the store path its current package installs.
  # The Dock stores a pin by its resolved path anyway, so pinning the link
  # in ~/Applications/Home Manager Apps would end up here too. An app
  # update changes the path, and so the settings below, which re-pins it.
  # mac-app-util's trampolines can't be pinned instead: each one is a
  # launcher that starts the real app as a second Dock icon, and it shows
  # a generic icon.
  hmApp =
    program: name:
    "${
      config.home-manager.users.${vars.username}.programs.${program}.package
    }/Applications/${name}.app";

  # The Dock's settings, in the form the Dock stores them
  dock = {
    tilesize = 79;
    show-recents = false;
    # Bottom-right hot corner: Quick Note
    wvous-br-corner = 14;

    persistent-apps =
      map
        (app: {
          tile-data.file-data = {
            _CFURLString = app;
            _CFURLStringType = 0;
          };
        })
        [
          "/System/Applications/Apps.app"
          "/System/Applications/Messages.app"
          "/System/Applications/Mail.app"
          "/System/Applications/System Settings.app"
          (hmApp "ghostty" "Ghostty")
          (hmApp "qutebrowser" "qutebrowser")
          "/Applications/Claude.app"
        ];
  };

  # One file per setting, holding its value as a plist. The directory's
  # store path changes only when a setting does.
  dockSettings = pkgs.linkFarm "dock-settings" (
    lib.mapAttrs (
      name: value: pkgs.writeText "${name}.plist" (lib.generators.toPlist { escape = true; } value)
    ) dock
  );

  stamp = "/var/lib/macos-dock/applied";
  asUser =
    cmd: ''launchctl asuser "$(id -u -- ${vars.username})" sudo --user=${vars.username} -- ${cmd}'';
in
{
  # Applies the Dock settings, and restarts the Dock to load them, only when
  # they differ from the last ones applied. nix-darwin's own Dock options
  # restart it on every switch, which brings it up over full-screen apps.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    if [ "$(cat ${stamp} 2>/dev/null)" != "${dockSettings}" ]; then
      echo "applying Dock settings..." >&2
      ${lib.concatMapStringsSep "\n" (
        name:
        asUser "defaults write com.apple.dock ${lib.escapeShellArg name} \"$(cat ${dockSettings}/${name})\""
      ) (lib.attrNames dock)}
      ${asUser "killall Dock"} || true
      mkdir -p ${dirOf stamp}
      echo "${dockSettings}" > ${stamp}
    fi
  '';

  system.defaults = {
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
