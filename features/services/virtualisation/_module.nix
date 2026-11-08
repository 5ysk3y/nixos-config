{
  vars,
  pkgs,
  ...
}:

{
  programs = {
    virt-manager.enable = true;

    # A SPICE console on the VM at 127.0.0.1:5900 (5901 with TLS)
    zsh.shellAliases.spicy = "spicy --spice-ca-file=/etc/pki/libvirt-spice/ca-cert.pem --uri 'spice://127.0.0.1' -p 5900 -s 5901 --title 'th3h4x0r' -f > /dev/null 2>&1 &|";
  };

  environment = {
    systemPackages = [ pkgs.spice-gtk ];
    # Docker clients talk to rootless podman
    sessionVariables.DOCKER_HOST = "unix://\${XDG_RUNTIME_DIR}/podman/podman.sock";
  };

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      dockerSocket.enable = false;
    };

    libvirtd = {
      enable = true;
      qemu.vhostUserPackages = [ pkgs.virtiofsd ];
    };
  };

  users.users.${vars.username} = {
    extraGroups = [ "libvirtd" ];
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
