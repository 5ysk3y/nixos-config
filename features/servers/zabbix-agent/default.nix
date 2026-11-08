{ config, ... }:
{
  flake.modules.nixos.zabbix-agent.imports = [
    config.flake.modules.nixos.firewall-allowlist
    ./_module.nix
  ];
}
