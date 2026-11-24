# Turns off Claude Desktop's own update checks, so updates come only through
# Nix.
#
# On Linux the app has no in-app updater. Instead it polls Anthropic's apt
# repo and shows an "Update available" button in the sidebar when the repo
# has a newer version. On a Nix install that button does nothing. The app's
# documented managed-config key disableAutoUpdates stops that poll. The app
# reads it from /etc/claude-desktop/managed-settings.json.
#
# The app opens that file with O_NOFOLLOW and requires both the file and its
# folder to be owned by root and not group- or world-writable. So mode must
# be set: that makes NixOS copy the file instead of symlinking it into
# /etc/static.
#
# The same key also stops desktop-extension auto-updates. The nixpkgs
# package already points the app at Nix's claude-code, which stops the app
# auto-updating that binary.
_: {
  environment.etc."claude-desktop/managed-settings.json" = {
    mode = "0444";
    text = builtins.toJSON { disableAutoUpdates = true; };
  };
}
