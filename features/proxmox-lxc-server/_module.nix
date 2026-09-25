# Shared baseline for NixOS servers running as unprivileged Proxmox LXCs,
# deployed remotely over the LAN with bootstrap/deploy.sh (root SSH,
# key-only). Each host sets its own address; everything else is common.
{
  config,
  lib,
  pkgs,
  hostname,
  modulesPath,
  ...
}:
let
  cfg = config.features.system.proxmoxLxcServer;
  gateway = "192.168.1.1";
  sshRule = action: ip: "iptables -${action} nixos-fw -p tcp -s ${ip} --dport 22 -j ACCEPT";
in
{
  imports = [
    "${modulesPath}/virtualisation/proxmox-lxc.nix"
  ];

  options.features.system.proxmoxLxcServer = {
    address = lib.mkOption {
      type = lib.types.str;
      example = "192.168.1.110";
      description = "Static LAN IPv4 address (/24) for eth0.";
    };
    rootAuthorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHDYsCglDjOEYHw6fpBL7KorictTA8314+K5VA6QaOko"
      ];
      description = "Keys allowed to SSH in as root (the deploy key used by bootstrap/deploy.sh).";
    };
    sshAllowedSources = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "192.168.1.100"
        "192.168.1.113"
      ];
      description = "LAN hosts allowed to reach sshd — the machines that run bootstrap/deploy.sh.";
    };
  };

  config = {
    networking = {
      hostName = hostname;
      useDHCP = false;
      interfaces.eth0.ipv4.addresses = [
        {
          inherit (cfg) address;
          prefixLength = 24;
        }
      ];
      defaultGateway = {
        address = gateway;
        interface = "eth0";
      };
      nameservers = [ gateway ];

      # SSH is not opened on the firewall generally (openFirewall = false
      # below); only the allowlisted deploy hosts get through.
      firewall.extraCommands = lib.concatMapStrings (ip: sshRule "A" ip + "\n") cfg.sshAllowedSources;
      firewall.extraStopCommands = lib.concatMapStrings (
        ip: sshRule "D" ip + " || true\n"
      ) cfg.sshAllowedSources;
    };

    services.resolved.enable = true;

    proxmoxLXC = {
      manageNetwork = false;
      privileged = false;
      manageHostName = true;
    };

    services.openssh = {
      enable = true;
      openFirewall = false;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "prohibit-password";
      };
    };

    users.users.root.openssh.authorizedKeys.keys = cfg.rootAuthorizedKeys;

    environment.systemPackages = with pkgs; [
      vim
      git
      curl
      wget
      openssl
    ];
  };
}
