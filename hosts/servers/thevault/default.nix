{ config, ... }:
{
  infra.hosts.thevault = {
    kind = "nixos-minimal";
    system = "x86_64-linux";

    systemModule = ./system.nix;

    systemProfiles = with config.infra.profiles.nixos; [
      base
      lxc-server
    ];
  };
}
