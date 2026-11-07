{ config, pkgs, ... }:
{
  # atticd's HS256 signing secret lives in /var/lib/attic/env, a plain
  # root:root 0600 file outside the Nix store — delivered by
  # bootstrap/servers/attic.sh (via deploy.sh) from nix-secrets (services.attic.server-token),
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
      # attic's documented sizes (book/src/admin-guide/chunking.md). Each
      # chunk is its own database writes, and the server uploads up to 10
      # of a NAR's chunks at once against SQLite's single writer; smaller
      # chunks made large NARs fail with "database is locked" and
      # connection-pool timeouts. Changing these stops existing chunks
      # being reused until the cache turns over (2-week retention).
      chunking = {
        nar-size-threshold = 131072;
        min-size = 65536;
        avg-size = 131072;
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

  # CI runners reach the cache API over Tailscale. Only :8080 is open on
  # the tailnet interface; everything else there (sshd included) stays
  # closed.
  networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [
    8080
  ];

  # Explicit LAN allowlist for the plain-HTTP :8080 API (the reverse
  # proxies) — everything else on the LAN is denied.
  features.system.firewallAllowlist."8080" = [
    "192.168.1.5"
    "192.168.1.7"
  ];

  environment.systemPackages = [
    pkgs.attic-client
  ];
}
