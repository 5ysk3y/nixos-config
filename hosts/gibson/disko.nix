{
  disk ? "/dev/vda",
  ...
}:

{
  disko.devices = {
    disk.main = {
      type = "disk";
      # The disk can be overriden with disko-install using, e.g. "--disk main /dev/vga"
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
              mountOptions = [ "umask=0700" ];
            };
          };

          luks = {
            size = "100%";

            content = {
              type = "luks";
              name = "cryptroot";

              askPassword = true;

              settings = {
                allowDiscards = true;
              };

              content = {
                type = "lvm_pv";
                vg = "vg0";
              };
            };
          };
        };
      };
    };

    lvm_vg.vg0 = {
      type = "lvm_vg";

      lvs = {
        swap = {
          size = "32G";

          content = {
            type = "swap";
            resumeDevice = true;
          };
        };

        root = {
          size = "100%FREE";

          content = {
            type = "filesystem";
            format = "xfs";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
