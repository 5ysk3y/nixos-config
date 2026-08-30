{
  pkgs,
  repoLib,
  ...
}:
{
  # Vaultwarden's secret env file (ADMIN_TOKEN, YUBICO_SECRET_KEY) lives at
  # /var/lib/vaultwarden-secrets/env, a plain root:root 0600 file outside
  # the Nix store — delivered by bootstrap/deploy-vaultwarden.sh from
  # nix-secrets. This host has no age key and no sops-nix module.
  services.vaultwarden = {
    enable = true;
    environmentFile = "/var/lib/vaultwarden-secrets/env";
    config = {
      DOMAIN = "https://bitwarden.home.arpa";
      ROCKET_ADDRESS = "0.0.0.0";
      ROCKET_PORT = 8000;
      SENDS_ALLOWED = true;
      INCOMPLETE_2FA_TIME_LIMIT = 3;
      DISABLE_ICON_DOWNLOAD = false;
      SIGNUPS_ALLOWED = true;
      SIGNUPS_VERIFY = false;
      SIGNUPS_VERIFY_RESEND_TIME = 3600;
      SIGNUPS_VERIFY_RESEND_LIMIT = 6;
      INVITATIONS_ALLOWED = true;
      EMERGENCY_ACCESS_ALLOWED = true;
      EMAIL_CHANGE_ALLOWED = true;
      PASSWORD_ITERATIONS = 600000;
      PASSWORD_HINTS_ALLOWED = true;
      SHOW_PASSWORD_HINT = false;
      INVITATION_ORG_NAME = "Vaultwarden";
      IP_HEADER = "X-Real-IP";
      ICON_REDIRECT_CODE = 302;
      ICON_CACHE_TTL = 2592000;
      ICON_CACHE_NEGTTL = 259200;
      ICON_DOWNLOAD_TIMEOUT = 10;
      HTTP_REQUEST_BLOCK_NON_GLOBAL_IPS = true;
      DISABLE_2FA_REMEMBER = false;
      AUTHENTICATOR_DISABLE_TIME_DRIFT = false;
      REQUIRE_DEVICE_EMAIL = false;
      RELOAD_TEMPLATES = false;
      LOG_TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M:%S.%3f";
      ADMIN_SESSION_LIFETIME = 20;
      INCREASE_NOTE_SIZE_LIMIT = false;
      YUBICO_CLIENT_ID = "107284";
    };
  };

  services.restic.backups.vaultwarden = repoLib.mkResticBackup {
    paths = [
      "/var/lib/vaultwarden/backup/db.sqlite3"
      "/var/lib/vaultwarden/rsa_key.pem"
      "/var/lib/vaultwarden/rsa_key.pub.pem"
      "/var/lib/vaultwarden/attachments"
      "/var/lib/vaultwarden/sends"
    ];
    repository = "sftp:networkBackup@backupServer.home.arpa:Linux/bitwarden";
    passwordFile = "/var/lib/vaultwarden-secrets/restic-password";
    extraOptions = [
      "sftp.command='ssh networkBackup@backupServer.home.arpa -i /var/lib/vaultwarden-secrets/restic-sftp-key -s sftp'"
    ];
    backupPrepareCommand = ''
      mkdir -p /var/lib/vaultwarden/backup
      ${pkgs.sqlite}/bin/sqlite3 /var/lib/vaultwarden/db.sqlite3 ".backup '/var/lib/vaultwarden/backup/db.sqlite3'"
    '';
  };

  # /var/lib/vaultwarden-secrets must exist before push_secrets' `install`
  # can write into it on a fresh host — declared here rather than left to
  # an undocumented manual mkdir before the first deploy.
  systemd.tmpfiles.rules = [
    "d /var/lib/vaultwarden-secrets 0700 root root -"
  ];

  environment.systemPackages = [
    pkgs.vaultwarden # for `vaultwarden hash` if the admin token ever needs regenerating
  ];

  # Standard LAN reverse proxy allow list
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -p tcp -s 192.168.1.5 --dport 8000 -j ACCEPT
    iptables -A nixos-fw -p tcp -s 192.168.1.7 --dport 8000 -j ACCEPT
  '';
  networking.firewall.extraStopCommands = ''
    iptables -D nixos-fw -p tcp -s 192.168.1.5 --dport 8000 -j ACCEPT || true
    iptables -D nixos-fw -p tcp -s 192.168.1.7 --dport 8000 -j ACCEPT || true
  '';
}
