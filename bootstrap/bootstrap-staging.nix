# Reusable Proxmox staging image for bootstrapping any new nix-based LXC — build
# it once, reuse the same tarball as a Proxmox CT template for every new server
# going forward.
#
# COMMAND
# *******
#
# nix run --extra-experimental-features "nix-command flakes" \
#  github:nix-community/nixos-generators -- \
#  --format proxmox-lxc \
#  -c ./bootstrap/bootstrap-staging.nix
#
# *******
#
# 192.168.1.150 is a fixed staging address, safe to reuse serially: only
# one host is ever mid-bootstrap at a time in this workflow, and each
# host's first real `bootstrap/deploy.sh <host>` run moves it onto its own
# permanent static IP (declared in hosts/servers/<host>/system.nix),
# freeing .150 for the next one.
#
# hostname deliberately left unset — irrelevant for this transient phase;
# each host's real hostname comes from its own flake config on first
# deploy.
_: {
  system.stateVersion = "25.05";

  networking = {
    useDHCP = false;
    interfaces.eth0.ipv4.addresses = [
      {
        address = "192.168.1.150";
        prefixLength = 24;
      }
    ];
    defaultGateway = {
      address = "192.168.1.1";
      interface = "eth0";
    };
    nameservers = [ "192.168.1.1" ];
  };

  services.resolved.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHDYsCglDjOEYHw6fpBL7KorictTA8314+K5VA6QaOko"
  ];
}
