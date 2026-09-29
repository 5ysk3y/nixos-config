# Source-restricted TCP allow rules. The NixOS iptables firewall has no
# per-source option, so features that serve a port to specific LAN hosts
# declare it here and the rules are generated once:
#
#   features.system.firewallAllowlist."8080" = [ "192.168.1.5" ];
#
# Import by name (config.flake.modules.nixos.firewall-allowlist) from the
# features that use it. No matching -D rules are needed: firewall start and
# reload flush the nixos-fw chain, and stop unhooks it from INPUT.
{ config, lib, ... }:
let
  cfg = config.features.system.firewallAllowlist;
  rule = port: ip: "iptables -A nixos-fw -p tcp -s ${ip} --dport ${port} -j ACCEPT\n";
in
{
  options.features.system.firewallAllowlist = lib.mkOption {
    type = lib.types.attrsOf (lib.types.listOf lib.types.str);
    default = { };
    example = {
      "8080" = [
        "192.168.1.5"
        "192.168.1.7"
      ];
    };
    description = ''
      TCP port (as a string) to the IPv4 source addresses allowed to reach
      it. Lists for the same port set by different modules are merged.
    '';
  };

  config = lib.mkIf (cfg != { }) {
    networking.firewall.extraCommands = lib.concatStrings (
      lib.mapAttrsToList (port: sources: lib.concatMapStrings (rule port) (lib.unique sources)) cfg
    );
  };
}
