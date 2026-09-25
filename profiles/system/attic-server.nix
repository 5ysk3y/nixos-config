{ config, ... }:
{
  infra.profiles.nixos.attic-server = {
    imports = with config.flake.modules.nixos; [
      attic-server
      tailscale
    ];
  };
}
