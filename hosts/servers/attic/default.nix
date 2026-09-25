{ config, ... }:
{
  # No home-manager, no sops-nix, no YubiKey — see flake/parts/platforms/nixos.nix
  # for what this kind skips.
  infra.hosts.attic = {
    kind = "nixos-minimal";
    system = "x86_64-linux";

    systemModule = ./system.nix;
    overlaysModule = ./overlays;

    systemProfiles = with config.infra.profiles.nixos; [
      nixos
      attic-server
    ];
  };
}
