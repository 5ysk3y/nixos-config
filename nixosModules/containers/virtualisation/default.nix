{
  config,
  lib,
  pkgs,
  vars,
  ...
}:

{
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      dockerSocket.enable = false;
    };

    libvirtd = {
      enable = true;
    };
  };

  users.users.${vars.username} = {
    subUidRanges = [
      {
        startUid = 100000;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        startGid = 100000;
        count = 65536;
      }
    ];
  };
}
