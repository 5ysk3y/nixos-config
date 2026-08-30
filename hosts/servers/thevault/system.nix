# theVault — Vaultwarden, Proxmox LXC, deployed remotely over the LAN
# from any machine which already has nix-secrets access:
#   nixos-rebuild switch --flake .#thevault --target-host root@192.168.1.9
# (root SSH is key-only below, so --use-remote-sudo isn't needed).
#
# Never `switch` locally on this host — same reasoning as attic: it has no
# access to fetch the private nix-secrets flake input, so local flake
# evaluation here is a non-starter regardless of what this host's own
# modules reference.
#
# No secrets live in this file or anywhere under the Nix store on this
# host. Vaultwarden's env file is delivered as a plain root:root 0600 file
# outside the store by bootstrap/deploy-vaultwarden.sh
{
  pkgs,
  hostname,
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/virtualisation/proxmox-lxc.nix"
  ];

  networking = {
    hostName = hostname;
    useDHCP = false;
    interfaces.eth0.ipv4.addresses = [
      {
        address = "192.168.1.9";
        prefixLength = 24;
      }
    ];
    defaultGateway = {
      address = "192.168.1.1";
      interface = "eth0";
    };
    nameservers = [
      "192.168.1.1"
    ];
  };

  proxmoxLXC = {
    manageNetwork = false;
    privileged = false;
    manageHostName = true;
  };

  services = {
    openssh = {
      enable = true;
      openFirewall = false;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "prohibit-password";
      };
    };
    resolved.enable = true;
    zabbixAgent.settings.Hostname = "theVault.home.arpa";
  };

  # Standard LAN ssh allow list
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -p tcp -s 192.168.1.100 --dport 22 -j ACCEPT
    iptables -A nixos-fw -p tcp -s 192.168.1.113 --dport 22 -j ACCEPT
  '';
  networking.firewall.extraStopCommands = ''
    iptables -D nixos-fw -p tcp -s 192.168.1.100 --dport 22 -j ACCEPT || true
    iptables -D nixos-fw -p tcp -s 192.168.1.113 --dport 22 -j ACCEPT || true
  '';

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHDYsCglDjOEYHw6fpBL7KorictTA8314+K5VA6QaOko"
  ];

  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    openssl
  ];

  system.stateVersion = "25.05";
}
