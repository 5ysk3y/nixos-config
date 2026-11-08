{ config, ... }:
{
  # Its staging image, for bootstrapping new LXCs, is hosts/images/lxc-staging
  flake.modules.nixos.proxmox-lxc-server.imports = [
    config.flake.modules.nixos.firewall-allowlist
    config.flake.modules.nixos.ssh-keys
    ./_module.nix
  ];
}
