{ pkgs, ... }:
{
  # atticd's HS256 signing secret lives in /var/lib/attic/env, a plain
  # root:root 0600 file outside the Nix store — delivered by
  # bootstrap/deploy-attic.sh from nix-secrets (services.attic.server-token),
  # not by sops-nix. This host intentionally has no age key, so it never
  # decrypts anything itself; systemd reads EnvironmentFile as root before
  # dropping to atticd's user, so the file's ownership doesn't need to
  # match the service user.
  services.atticd = {
    enable = true;
    user = "atticd";
    group = "atticd";
    environmentFile = "/var/lib/attic/env";
    settings = {
      listen = "[::]:8080";
      allowed-hosts = [
        "attic.home.arpa"
        "attic.taileda465.ts.net"
        "attic.taileda465.ts.net:8080"
      ];
      database.url = "sqlite:///var/lib/atticd/server.db?mode=rwc";
      storage = {
        type = "local";
        path = "/mnt/attic-cache";
      };
      chunking = {
        nar-size-threshold = 65536;
        min-size = 16384;
        avg-size = 65536;
        max-size = 262144;
      };
      garbage-collection = {
        interval = "12 hours";
        default-retention-period = "2 weeks";
      };
    };
  };

  # uid/gid pinned to match ownership on the existing NFS-backed
  # /mnt/attic-cache bind mount — do not renumber without also chowning
  # the storage path.
  users.users.atticd = {
    isSystemUser = true;
    group = "atticd";
    uid = 990;
  };
  users.groups.atticd.gid = 990;

  # Explicit LAN allowlist for the plain-HTTP :8080 API — everything else
  # on the LAN is denied; Tailscale clients bypass this entirely via
  # networking.firewall.trustedInterfaces (see features/tailscale).
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -p tcp -s 192.168.1.5 --dport 8080 -j ACCEPT
    iptables -A nixos-fw -p tcp -s 192.168.1.7 --dport 8080 -j ACCEPT
  '';
  networking.firewall.extraStopCommands = ''
    iptables -D nixos-fw -p tcp -s 192.168.1.5 --dport 8080 -j ACCEPT || true
    iptables -D nixos-fw -p tcp -s 192.168.1.7 --dport 8080 -j ACCEPT || true
  '';

  environment.systemPackages = [
    pkgs.attic-client
  ];
}
