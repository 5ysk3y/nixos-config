# System side of Claude Desktop: the package (temporarily, via the vendored
# overlay) and what Cowork's QEMU/KVM VM needs, per Anthropic's Linux docs
# (code.claude.com/docs/en/desktop-linux). Pair with
# flake.modules.homeManager.claude-desktop, which installs the app.
{ inputs, vars, ... }:
let
  entries = import ./_overlay-entries.nix { inherit inputs; };
in
{
  # System level on purpose: with home-manager.useGlobalPkgs = true, an
  # nixpkgs.overlays set in a Home Manager module has no effect.
  nixpkgs.overlays = [ entries.permanent ] ++ map (e: e.overlay) entries.tracked;

  # Cowork's launch check reports a missing vhost_vsock module
  boot.kernelModules = [ "vhost_vsock" ];

  # The docs require the kvm group: /dev/vhost-vsock is only open to its members
  users.users.${vars.username}.extraGroups = [ "kvm" ];
}
