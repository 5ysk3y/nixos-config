{ config, ... }:
{
  infra.hosts.thevault = {
    kind = "nixos-minimal";
    system = "x86_64-linux";

    systemModule = ./system.nix;
    overlaysModule = ./overlays;

    systemProfiles = with config.infra.profiles.nixos; [
      nixos
      vaultwarden
      zabbix-agent
    ];
  };
}
