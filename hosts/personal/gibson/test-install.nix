# gibson's config, installed to a disk other than its own NVMe: for
# rehearsing a reinstall end to end (bootstrap/README.md, "Rehearsing a
# reinstall") with no risk to the live system. Used by the gibson-test-*
# configurations in default.nix.
#
# Everything else is gibson's own config, except:
#   - the disk, and its labels: partitions gibson-test-{ESP,SWAP,ROOT} and
#     filesystems/LUKS TBOOT, TROOT, TSWAP, trootfs and tswap. Neither the
#     install nor the test system can then format, mount or unlock the live
#     disk (disk-main-*, BOOT, ROOT, ...) while both are attached
#   - the firmware's boot entries are left alone; boot the test disk from the
#     firmware's boot menu instead
#   - the games disk isn't mounted: even a read-only ext4 mount can write
#     (fsck, journal replay), which would corrupt it if a hibernated gibson
#     still has it mounted
#   - nothing that acts as gibson on the network runs: no Tailscale, no
#     Syncthing, no scheduled backup, no pushes to attic
{
  device,
  initrdModules,
}:
{ lib, vars, ... }:
let
  label = {
    boot = "TBOOT";
    root = "TROOT";
    swap = "TSWAP";
    rootfs = "trootfs";
    swapfs = "tswap";
  };
in
{
  disko.devices.disk.main = {
    device = lib.mkForce device;
    content.partitions = {
      ESP = {
        label = "gibson-test-ESP";
        content.extraArgs = lib.mkForce [
          "-n"
          label.boot
        ];
      };
      SWAP.label = "gibson-test-SWAP";
      SWAP.content = {
        extraFormatArgs = lib.mkForce [
          "--label"
          label.swap
        ];
        content.extraArgs = lib.mkForce [
          "-L"
          label.swapfs
        ];
      };
      ROOT.label = "gibson-test-ROOT";
      ROOT.content = {
        extraFormatArgs = lib.mkForce [
          "--label"
          label.root
        ];
        content.extraArgs = lib.mkForce [
          "-L"
          label.rootfs
        ];
      };
    };
  };

  boot = {
    initrd = {
      luks.devices = {
        rootfs.device = lib.mkForce "/dev/disk/by-label/${label.root}";
        swap.device = lib.mkForce "/dev/disk/by-label/${label.swap}";
      };
      # The test disk's controller, which gibson's own initrd doesn't need
      availableKernelModules = initrdModules;
    };
    resumeDevice = lib.mkForce "/dev/disk/by-label/${label.swapfs}";
    loader.efi.canTouchEfiVariables = lib.mkForce false;
  };

  fileSystems = {
    "/".device = lib.mkForce "/dev/disk/by-label/${label.rootfs}";
    "/boot".device = lib.mkForce "/dev/disk/by-label/${label.boot}";
    "/home/${vars.username}/games".options = [ "noauto" ];
  };
  swapDevices = lib.mkForce [ { device = "/dev/disk/by-label/${label.swapfs}"; } ];

  services.tailscale.enable = lib.mkForce false;
  services.restic.backups.gibson.timerConfig = lib.mkForce null;
  systemd.services.attic-watch-store.enable = lib.mkForce false;
  home-manager.users.${vars.username}.features.home.syncthing.enable = lib.mkForce false;
}
