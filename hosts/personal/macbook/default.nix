{ config, ... }:
{
  infra.hosts.macbook = {
    kind = "darwin";
    system = "aarch64-darwin";

    systemModule = ./system.nix;
    homeModule = ./home.nix;
    overlayEntries = ./overlays/overlay-entries.nix;

    systemProfiles = with config.infra.profiles.darwin; [
      base
      personal
    ];

    homeProfiles = with config.infra.profiles.homeManager; [
      common
      personal
      darwin
    ];
  };
}
