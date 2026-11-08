{ config, ... }:
{
  flake.modules.nixos.attic-server.imports = [
    config.flake.modules.nixos.firewall-allowlist
    ./_module.nix
  ];
}
