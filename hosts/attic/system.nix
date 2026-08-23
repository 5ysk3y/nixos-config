# Attic binary cache — Proxmox LXC, deployed remotely over the LAN
# from any machine which already has nix-secrets access:
#   nixos-rebuild switch --flake .#attic --target-host root@192.168.1.110
# (root SSH is key-only below, so --use-remote-sudo isn't needed).
#
# Never `switch` locally on this host — see the repo README/CI notes on why
# nix-secrets makes local flake evaluation here a non-starter regardless of
# what this host's own modules reference.
#
# Tailscale on this host is unrelated to the above — it exists solely so
# GitHub Actions runners can reach the :8080 cache API for CI build/push,
# same as the CI-facing allowed-hosts entries in features/attic-server.
# It plays no part in LAN admin/deploy access.
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
        address = "192.168.1.110";
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

  services.resolved.enable = true;

  proxmoxLXC = {
    manageNetwork = false;
    privileged = false;
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

  # LAN allowlist for SSH — same extraCommands pattern as atticd's :8080
  # allowlist below, scoped to just gibson (192.168.1.100), the only host
  # that ever deploys to attic.
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -p tcp -s 192.168.1.100 --dport 22 -j ACCEPT
    iptables -A nixos-fw -p tcp -s 192.168.1.113 --dport 22 -j ACCEPT
  '';
  networking.firewall.extraStopCommands = ''
    iptables -D nixos-fw -p tcp -s 192.168.1.100 --dport 22 -j ACCEPT || true
    iptables -D nixos-fw -p tcp -s 192.168.1.113 --dport 22 -j ACCEPT || true
  '';

  # TODO: replace with gibson's actual SSH public key (e.g. from
  # /etc/ssh/ssh_host_ed25519_key.pub or a dedicated deploy keypair) —
  # required for `nixos-rebuild --target-host` to reach this box.
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

  system.stateVersion = "25.05"; # inherited from the original LXC install — do not bump to match other hosts
}
