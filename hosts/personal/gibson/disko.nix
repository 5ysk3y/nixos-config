# gibson's system disk: how disko partitions and formats it at install time
# (nixos-anywhere), and how the system unlocks and mounts it, since disko
# generates the LUKS device, filesystems, swap and resume device from this.
# Never the games disk: that's a separate device, mounted by
# hardware-configuration.nix and not listed here.
#
#   ESP    1G     vfat, /boot
#   ROOT   rest   LUKS2 -> LVM -> swap  32G   (also the hibernation image)
#                              -> root  rest  XFS, /
#
# One LUKS container holds both swap and root, so a single unlock (a
# YubiKey's FIDO2 token, or the passphrase) opens everything, including a
# hibernation image, and no key is kept anywhere unencrypted.
#
# The names are options so the gibson-test-* configurations
# (test-install.nix) can give a test disk names of its own: the live disk
# can then never be formatted, unlocked or mounted in their place.
#
# The disk passphrase is supplied at install time, without a trailing
# newline, as /tmp/disko-luks-password. FIDO2 tokens are enrolled after the
# first boot (bootstrap/README.md, step 6).
{ config, lib, ... }:
let
  cfg = config.gibson.disk;
  name =
    default: description:
    lib.mkOption {
      type = lib.types.str;
      inherit default description;
    };
in
{
  options.gibson.disk = {
    device = lib.mkOption {
      type = lib.types.str;
      description = "The whole disk to install to, by its /dev/disk/by-id link.";
    };
    names = {
      espPartition = name "disk-main-ESP" "GPT partition name of the ESP.";
      luksPartition = name "disk-main-ROOT" "GPT partition name of the LUKS container.";
      espLabel = name "BOOT" "Filesystem label of the ESP.";
      luks = name "cryptroot" "dm-crypt name of the opened LUKS container.";
      vg = name "gibson" "LVM volume group inside the LUKS container.";
      rootLabel = name "rootfs" "Filesystem label of the root volume.";
      swapLabel = name "swap" "Label of the swap volume.";
    };
  };

  config = {
    # Initrd secrets are written, unencrypted, into the initrd on the ESP
    assertions = [
      {
        assertion = config.boot.initrd.secrets == { };
        message = "gibson: boot.initrd.secrets would be stored unencrypted on the ESP; keep keys inside the LUKS container instead (see disko.nix).";
      }
    ];

    gibson.disk.device = lib.mkDefault "/dev/disk/by-id/nvme-Fanxiang_S500Pro_512GB_FXS500Pro250940463";

    disko.devices = {
      disk.main = {
        type = "disk";
        inherit (cfg) device;
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              label = cfg.names.espPartition;
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                # Root-only, so systemd-boot's random seed isn't world-readable
                mountOptions = [ "umask=0077" ];
                extraArgs = [
                  "-n"
                  cfg.names.espLabel
                ];
              };
            };
            ROOT = {
              priority = 2;
              label = cfg.names.luksPartition;
              size = "100%";
              content = {
                type = "luks";
                name = cfg.names.luks;
                passwordFile = "/tmp/disko-luks-password";
                settings = {
                  # Pass TRIM through to the SSD, so the default weekly fstrim
                  # (services.fstrim) reaches it
                  allowDiscards = true;
                  # Unlock with an enrolled YubiKey; the passphrase if none is
                  # plugged in within 30 seconds
                  crypttabExtraOpts = [
                    "fido2-device=auto"
                    "token-timeout=30"
                  ];
                };
                content = {
                  type = "lvm_pv";
                  inherit (cfg.names) vg;
                };
              };
            };
          };
        };
      };

      lvm_vg.${cfg.names.vg} = {
        type = "lvm_vg";
        lvs = {
          swap = {
            size = "32G";
            content = {
              type = "swap";
              resumeDevice = true;
              extraArgs = [
                "-L"
                cfg.names.swapLabel
              ];
            };
          };
          # Created after swap ("100%" is the volume group's free space)
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = "/";
              extraArgs = [
                "-L"
                cfg.names.rootLabel
              ];
            };
          };
        };
      };
    };
  };
}
