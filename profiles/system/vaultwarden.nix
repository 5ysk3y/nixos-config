{ config, ... }:
{
  infra.profiles.nixos.vaultwarden = {
    imports = with config.flake.modules.nixos; [
      vaultwarden
    ];
  };
}
