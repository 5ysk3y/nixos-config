{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.modules.nixos.zabbix-agent
  ];
}
