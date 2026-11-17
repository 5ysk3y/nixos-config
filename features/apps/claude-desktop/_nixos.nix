# System side of Claude Desktop: what Cowork's QEMU/KVM VM needs, per
# Anthropic's Linux docs (code.claude.com/docs/en/desktop-linux). The
# package's overlay is applied alongside this module (see default.nix), and
# flake.modules.homeManager.claude-desktop installs the app.
{ vars, ... }:
{
  # Cowork's launch check reports a missing vhost_vsock module
  boot.kernelModules = [ "vhost_vsock" ];

  # The docs require the kvm group: /dev/vhost-vsock is only open to its members
  users.users.${vars.username}.extraGroups = [ "kvm" ];
}
