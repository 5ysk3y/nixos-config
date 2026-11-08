{ config, ... }:
{
  flake.modules.nixos.vaultwarden.imports = [
    config.flake.modules.nixos.firewall-allowlist
    ./_module.nix
  ];
}
