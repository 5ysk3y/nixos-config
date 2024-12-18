# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, system, vars, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot = {
    kernelPackages = pkgs.linuxPackages_xanmod_stable;
    kernelModules = [ "kvm-amd" "amdgpu" "i2c-dev" "i2c-piix4" "k10temp" ];
    kernelParams = [
      "video=DP-1:2560x1440@144"
      "video=DP-2:1920x1080@144"
      "video=HDMI-A-2:1920x1080@60"
      "acpi_enforce_resources=lax"
    ];
    extraModulePackages = with config.boot.kernelPackages; [ ];
    loader = {
      systemd-boot = {
        enable = true;
      };
      efi = {
        canTouchEfiVariables = true;
      };
    };
    initrd = {
      luks = {
        devices = {
          "rootfs" = {
            device = "/dev/disk/by-uuid/ff1a20da-b20b-4dbb-9d0d-1471a4bb141f";
          };
          "swap" = {
            device = "/dev/disk/by-uuid/13479741-2586-406b-9016-048d6937f0b7";
          };
        };
      };
      systemd = {
        enable = true;
      };
      kernelModules = [ "amdgpu" ];
      availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "sd_mod" ];
    };
  };

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/8cf36eb1-f7ac-4eb0-9e28-0781d1cebd54";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/FF2C-C169";
      fsType = "vfat";
    };

  fileSystems."/home/${vars.username}/games" =
    { device = "/dev/disk/by-uuid/a454d05d-903b-4418-916f-6f2c69653e60";
      fsType = "ext4";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/22e7db71-e91f-4a00-ab2e-43b928409160"; }
    ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno1.useDHCP = lib.mkDefault true;
  # networking.interfaces.virbr0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "${system}";
}
