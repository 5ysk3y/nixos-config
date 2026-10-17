# gibson's system disk, as disko partitions and formats it at install time
# (nixos-anywhere or disko-install). Never the games disk: that's a separate
# device, mounted by hardware-configuration.nix and not listed here.
#
# disko.enableConfig is off: the running system mounts and unlocks the disk
# through hardware-configuration.nix, by the labels set here (BOOT, ROOT,
# SWAP, rootfs, swap). The current disk predates this layout and lacks
# disko's partition names, but it carries the same labels, so both the
# current disk and a freshly installed one boot from the same config. Keep
# the labels here and in hardware-configuration.nix in step.
#
# Secrets supplied at install time, written without a trailing newline:
#   /tmp/disko-luks-password  the disk passphrase (root, and swap's fallback)
#   /swap.key                 swap's keyfile, the one at /etc/secrets/swap.key
_: {
  disko.enableConfig = false;

  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/nvme-Fanxiang_S500Pro_512GB_FXS500Pro250940463";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 1;
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
            extraArgs = [
              "-n"
              "BOOT"
            ];
          };
        };
        SWAP = {
          priority = 2;
          size = "32G";
          content = {
            type = "luks";
            name = "swap";
            extraFormatArgs = [
              "--label"
              "SWAP"
            ];
            settings = {
              allowDiscards = true;
              # Formats swap with this key; at boot it's the initrd secret
              # declared in hardware-configuration.nix
              keyFile = "/swap.key";
            };
            # The passphrase as a second key, in case the keyfile is missing
            additionalKeyFiles = [ "/tmp/disko-luks-password" ];
            content = {
              type = "swap";
              extraArgs = [
                "-L"
                "swap"
              ];
            };
          };
        };
        ROOT = {
          priority = 3;
          size = "100%";
          content = {
            type = "luks";
            name = "rootfs";
            passwordFile = "/tmp/disko-luks-password";
            extraFormatArgs = [
              "--label"
              "ROOT"
            ];
            settings.allowDiscards = true;
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = "/";
              extraArgs = [
                "-L"
                "rootfs"
              ];
            };
          };
        };
      };
    };
  };
}
