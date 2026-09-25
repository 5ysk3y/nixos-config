{ config, inputs, ... }:
{
  flake.modules.nixos.proxmox-lxc-server = ./_module.nix;

  # Reusable Proxmox staging image for bootstrapping any new nix-based LXC —
  # build it once, reuse the same tarball as a Proxmox CT template for every
  # new server going forward.
  #
  # BUILD
  #   nixos-rebuild build-image --image-variant proxmox-lxc --flake .#lxc-staging
  #
  # Once the container image is available in Proxmox:
  #   pct create <CTID> local:vztmpl/image-name.tar.xz \
  #     --unprivileged 1 \
  #     --features nesting=1 \
  #     --net0 name=eth0,bridge=vmbr0,firewall=1 \
  #     --rootfs local-lvm:4 \
  #     --cores <NUM> \
  #     --memory <NUM> \
  #     --swap <NUM>
  #
  # 192.168.1.150 is a fixed staging address, safe to reuse serially: only
  # one host is ever mid-bootstrap at a time in this workflow, and each
  # host's first real `bootstrap/deploy.sh <host>` run moves it onto its own
  # permanent static IP, freeing .150 for the next one.
  flake.nixosConfigurations.lxc-staging = inputs.nixpkgs.lib.nixosSystem {
    specialArgs.hostname = "lxc-staging";
    modules = [
      config.flake.modules.nixos.proxmox-lxc-server
      {
        nixpkgs.hostPlatform = "x86_64-linux";
        features.system.proxmoxLxcServer.address = "192.168.1.150";
        system.stateVersion = "25.05";
      }
    ];
  };
}
