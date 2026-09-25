{ config, ... }:
{
  infra.profiles.nixos.nixos = {
    imports = with config.flake.modules.nixos; [
      editor
      locale
      nix-settings
      overlays
      security
    ];
  };
}
