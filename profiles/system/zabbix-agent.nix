{ config, ... }:
{
  infra.profiles.nixos.zabbix-agent = {
    imports = with config.flake.modules.nixos; [
      zabbix-agent
    ];
  };
}
