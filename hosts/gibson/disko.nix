{
  disk ? "/dev/vda",
  ...
}:
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = disk;
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
              passwordFile = "/tmp/disko-luks-password";
              extraFormatArgs = [
                "--label"
                "SWAP"
              ];
              settings = {
                allowDiscards = true;
              };
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
              settings = {
                allowDiscards = true;
              };
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
  };
}
