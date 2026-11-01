# gibson's config, installed to a disk other than its own NVMe: for
# rehearsing a reinstall end to end (bootstrap/README.md, "Rehearsing a
# reinstall") with no risk to the live system. Used by the gibson-test-*
# configurations in default.nix.
#
# Everything else is gibson's own config, except:
#   - the disk, and every name on it: partitions gibson-test-{ESP,ROOT}, the
#     LUKS container tcryptroot, volume group tgibson, and labels TBOOT,
#     trootfs and tswap. Neither the install nor the test system can then
#     format, unlock or mount the live disk (disk-main-*, cryptroot, gibson)
#     while both are attached
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
{
  gibson.disk = {
    inherit device;
    names = {
      espPartition = "gibson-test-ESP";
      luksPartition = "gibson-test-ROOT";
      espLabel = "TBOOT";
      luks = "tcryptroot";
      vg = "tgibson";
      rootLabel = "trootfs";
      swapLabel = "tswap";
    };
  };

  boot = {
    # The test disk's controller, which gibson's own initrd doesn't need
    initrd.availableKernelModules = initrdModules;
    loader.efi.canTouchEfiVariables = lib.mkForce false;
  };

  fileSystems."/home/${vars.username}/games".options = [ "noauto" ];

  services.tailscale.enable = lib.mkForce false;
  services.restic.backups.gibson.timerConfig = lib.mkForce null;
  systemd.services.attic-watch-store.enable = lib.mkForce false;
  home-manager.users.${vars.username}.features.home.syncthing.enable = lib.mkForce false;
}
