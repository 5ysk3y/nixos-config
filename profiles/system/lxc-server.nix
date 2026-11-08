# Servers running as unprivileged Proxmox LXCs, deployed with
# bootstrap/deploy.sh. Each host adds its own role's features in system.nix.
{ config, ... }:
{
  infra.profiles.nixos.lxc-server = {
    imports = with config.flake.modules.nixos; [
      proxmox-lxc-server
    ];
  };
}
