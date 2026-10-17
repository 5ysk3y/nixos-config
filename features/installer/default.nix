{ inputs, ... }:
let
  mkInstaller =
    module:
    inputs.nixpkgs.lib.nixosSystem {
      modules = [
        module
        { nixpkgs.hostPlatform = "x86_64-linux"; }
      ];
    };
in
{
  # Installers for the personal machines, with YubiKey support built in:
  # pcscd, gpg-agent with SSH support and age-plugin-yubikey work as soon as a
  # key is plugged in. Both variants share _common.nix; they only differ in
  # how they boot. Build either on an x86_64-linux machine.
  #
  # The installer only has to boot and run the install: the system it
  # installs is built from the flake at install time, so an old build keeps
  # working. Rebuild when it stops booting the hardware, not on a schedule.
  #
  # USB stick:
  #   nix build .#nixosConfigurations.installer.config.system.build.isoImage
  #   sudo dd if=result/iso/<name>.iso of=/dev/sdX bs=4M status=progress conv=fsync
  #
  # netboot.xyz (self-hosted container): copy the files into the container's
  # assets directory, served by its nginx (port 8080 by default):
  #   nix build .#nixosConfigurations.installer-netboot.config.system.build.netbootTree
  #   rsync -rL --chmod=F644 result/ <host>:<assets>/nixos-installer/
  # then point netboot.xyz's custom URL menu at it, in /config/menus/local-vars.ipxe:
  #   set custom_url http://<host>:8080/nixos-installer
  # and choose "Custom URL Menu" from the netboot.xyz main menu.
  flake.nixosConfigurations = {
    installer = mkInstaller ./_iso.nix;
    installer-netboot = mkInstaller ./_netboot.nix;
  };
}
