{ config, ... }:
{
  infra.hosts.gibson = {
    kind = "nixos";
    system = "x86_64-linux";

    systemModule = ./system.nix;
    homeModule = ./home.nix;
    overlaysModule = ./overlays;

    systemProfiles = with config.infra.profiles.nixos; [
      nixos
      desktop
    ];

    homeProfiles = with config.infra.profiles.homeManager; [
      common
      desktop
    ];
  };
}
