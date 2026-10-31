{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:
let
  inherit (config.system) build;

  # Shown by netboot.xyz's "Custom URL Menu", which chains ${custom_url}/custom.ipxe.
  #
  # The installer entry boots the kernel itself instead of chaining
  # netboot.ipxe, so it can imgfree first: on UEFI, iPXE hands the kernel
  # every image it still has loaded as one initrd, netboot.xyz's own menu
  # scripts included. Those come first, so the kernel stops unpacking at
  # their text, never finds /init and panics. The kernel line is the one
  # netboot.ipxe uses, with ${cmdline} kept for extra parameters.
  customMenu = pkgs.writeText "custom.ipxe" ''
    #!ipxe
    :custom
    menu nixos-config
    item installer NixOS installer (YubiKey ready)
    choose custom_choice || goto custom_exit
    goto ''${custom_choice}

    :installer
    imgfree
    kernel ''${custom_url}/bzImage init=${build.toplevel}/init initrd=initrd ${toString config.boot.kernelParams} ''${cmdline} || goto custom_exit
    initrd ''${custom_url}/initrd || goto custom_exit
    boot || goto custom_exit

    :custom_exit
    exit
  '';
in
{
  imports = [
    "${modulesPath}/installer/netboot/netboot-minimal.nix"
    ./_common.nix
  ];

  # netboot-minimal turns firmware off (at priority 70) to keep the image
  # small; the installer has to bring up whatever NIC it lands on.
  hardware.enableRedistributableFirmware = lib.mkOverride 60 true;

  # A live system with no state to migrate; same as the ISO's installation-cd-base.
  system.stateVersion = lib.mkDefault lib.trivial.release;

  # Everything netboot.xyz needs, in one directory.
  system.build.netbootTree = pkgs.linkFarm "installer-netboot" [
    {
      name = "bzImage";
      path = "${build.kernel}/${config.system.boot.loader.kernelFile}";
    }
    {
      name = "initrd";
      path = "${build.netbootRamdisk}/initrd";
    }
    {
      name = "netboot.ipxe";
      path = "${build.netbootIpxeScript}/netboot.ipxe";
    }
    {
      name = "custom.ipxe";
      path = customMenu;
    }
  ];
}
