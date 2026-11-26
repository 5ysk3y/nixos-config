# Needs flake.modules.nixos.claude-desktop on the same host: until
# NixOS/nixpkgs#587988 merges, pkgs.claude-desktop only exists through its
# overlay.
{ pkgs, ... }:
{
  home.packages = [
    # Chromium chooses safeStorage's backend from XDG_CURRENT_DESKTOP. It
    # doesn't recognise Hyprland, so it would use "basic_text" and the app
    # would never save its sign-in. This points it at the Secret Service
    # that ./_keyring.nix runs.
    (pkgs.claude-desktop.override {
      commandLineArgs = "--password-store=gnome-libsecret";
    })
  ];
}
