{ config, ... }:
let
  testInstall =
    args:
    config.flake.nixosConfigurations.gibson.extendModules {
      modules = [ (import ./test-install.nix args) ];
    };
in
{
  infra.hosts.gibson = {
    kind = "nixos";
    system = "x86_64-linux";

    systemModule = ./system.nix;
    homeModule = ./home.nix;
    overlaysModule = ./overlays;

    systemProfiles = with config.infra.profiles.nixos; [
      nixos
      desktop
    ];

    homeProfiles = with config.infra.profiles.homeManager; [
      common
      desktop
    ];
  };

  # gibson installed somewhere other than its own NVMe, to rehearse a
  # reinstall (see test-install.nix and bootstrap/README.md)
  flake.nixosConfigurations = {
    # On gibson itself, to an external USB disk
    gibson-test-usb = testInstall {
      device = "/dev/disk/by-id/usb-SET-ME";
      initrdModules = [
        "usb_storage"
        "uas"
      ];
    };
    # In a VM, to a virtio disk with the serial number gibson-test
    gibson-test-vm = testInstall {
      device = "/dev/disk/by-id/virtio-gibson-test";
      initrdModules = [
        "virtio_pci"
        "virtio_blk"
      ];
    };
  };
}
