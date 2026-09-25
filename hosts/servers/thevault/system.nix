# theVault — Vaultwarden, Proxmox LXC, deployed remotely over the LAN
# from any machine which already has nix-secrets access:
#   bootstrap/deploy.sh thevault
# (root SSH is key-only, see features/proxmox-lxc-server).
#
# Never `switch` locally on this host — same reasoning as attic: it has no
# access to fetch the private nix-secrets flake input, so local flake
# evaluation here is a non-starter regardless of what this host's own
# modules reference.
#
# No secrets live in this file or anywhere under the Nix store on this
# host. Vaultwarden's env file is delivered as a plain root:root 0600 file
# outside the store by bootstrap/servers/thevault.sh (via bootstrap/deploy.sh).
{ inputs, ... }:
{
  imports = [
    inputs.self.modules.nixos.proxmox-lxc-server
  ];

  features.system.proxmoxLxcServer.address = "192.168.1.9";

  services.zabbixAgent.settings.Hostname = "theVault.home.arpa";

  system.stateVersion = "25.05";
}
