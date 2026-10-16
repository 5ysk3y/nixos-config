# Attic binary cache — Proxmox LXC, deployed remotely over the LAN
# from any machine which already has nix-secrets access:
#   bootstrap/deploy.sh attic
# (root SSH is key-only, see features/proxmox-lxc-server).
#
# Never `switch` locally on this host: it has no access to fetch the
# private nix-secrets flake input, so local flake evaluation here is a
# non-starter regardless of what this host's own modules reference.
#
# Tailscale on this host is unrelated to the above — it exists solely so
# GitHub Actions runners can reach the :8080 cache API for CI build/push,
# same as the CI-facing allowed-hosts entries in features/attic-server.
# It plays no part in LAN admin/deploy access.
{ inputs, ... }:
{
  imports = [
    inputs.self.modules.nixos.proxmox-lxc-server
  ];

  features.system.proxmoxLxcServer.address = "192.168.1.110";

  system.stateVersion = "25.05"; # inherited from the original LXC install — do not bump to match other hosts
}
