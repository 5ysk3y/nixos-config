{ config, ... }:
{
  infra.hosts.macbook = {
    kind = "darwin";
    system = "aarch64-darwin";

    systemModule = ./system.nix;
    homeModule = ./home.nix;
    overlaysModule = ./overlays;

    systemProfiles = with config.infra.profiles.darwin; [
      darwin
    ];

    homeProfiles = with config.infra.profiles.homeManager; [
      common
      darwin
    ];
  };
}
