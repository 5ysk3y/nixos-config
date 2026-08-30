{ pkgs, ... }:
{
  # Hostname is deliberately NOT set here — it has to match a host's existing
  # Zabbix inventory entry exactly (case, domain suffix and all), which this
  # shared module has no way to know. Each host sets it via
  # services.zabbixAgent.settings.Hostname on top of this.
  services.zabbixAgent = {
    enable = true;
    package = pkgs.zabbix70.agent2;
    server = "192.168.1.3";
    settings = {
      LogFile = "/var/log/zabbix/zabbix_agent2.log";
      ServerActive = "192.168.1.3";
      PluginSocket = "/run/zabbix/agent.plugin.sock";
      ControlSocket = "/run/zabbix/zabbix_agent2.sock";
      Include = "/etc/zabbix/zabbix_agent2.d/plugins.d/*.conf";
    };
  };

  # To ensure the plugins directory above exists
  systemd.tmpfiles.rules = [
    "d /etc/zabbix/zabbix_agent2.d/plugins.d 0755 root root -"
    "d /run/zabbix 0755 zabbix-agent zabbix-agent -"
  ];

  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -p tcp -s 192.168.1.3 --dport 10050 -j ACCEPT
  '';
  networking.firewall.extraStopCommands = ''
    iptables -D nixos-fw -p tcp -s 192.168.1.3 --dport 10050 -j ACCEPT || true
  '';
}
