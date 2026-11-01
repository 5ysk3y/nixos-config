# The values bootstrap/README.md's gibson checklist uses, read from this
# config so the checklist can't drift from it. Step 1 loads them on the Mac:
#
#   eval "$(nix eval --raw .#nixosConfigurations.$HOST.config.system.build.bootstrapEnv)"
#
# which sets the variables below and prints them. The gibson-test-*
# configurations extend this one, so their values (TROOT and so on) follow.
{
  config,
  lib,
  vars,
  hostname,
  ...
}:
let
  backupName = "${hostname}";
  backup = config.services.restic.backups.${backupName};

  # sftp:<user>@<host>:<path>
  repoParts = builtins.match "sftp:([^@]+)@([^:]+):(.*)" backup.repository;
  sftpUser = builtins.elemAt repoParts 0;
  backupHost = builtins.elemAt repoParts 1;

  partitions = config.disko.devices.disk.main.content.partitions;
  swapKey = partitions.SWAP.content.settings.keyFile;
  ageKeys = "${vars.secretsPath}/bootstrap/age-keys.txt.age";
  gamesDir = "/home/${vars.username}/games";

  # Restored on the Mac and copied in by nixos-anywhere, because the install
  # or the first boot needs them: the user/group ID maps, so restored files
  # keep their owners; the SSH host keys and machine-id; NetworkManager's
  # connections; and the swap keyfile.
  preInstallRestore = [
    "/var/lib/nixos"
    "/etc/ssh/ssh_host_*"
    "/etc/machine-id"
    "/etc/NetworkManager/system-connections"
    "/etc/secrets"
  ];

  # The fixed part of a path, up to any glob
  literalPrefix = p: builtins.head (builtins.match "([^*?[]*).*" p);
  backedUp =
    p:
    let
      prefix = literalPrefix p;
    in
    builtins.any (b: prefix == b || lib.hasPrefix "${lib.removeSuffix "/" b}/" prefix) backup.paths;

  vals = {
    BACKUP_HOST = backupHost;
    BACKUP_HOST_KEY = "${backupHost} ${config.programs.ssh.knownHosts.${backupHost}.publicKey}";
    RESTIC_REPOSITORY = backup.repository;
    RESTIC_SFTP_USER = sftpUser;
    RESTIC_WRAPPER = "restic-${backupName}";
    RESTIC_PASSWORD_SOPS = toString config.sops.secrets.restic-password.sopsFile;
    RESTIC_SFTP_KEY_SOPS = toString config.sops.secrets.restic-sftp-key.sopsFile;
    AGE_KEYS = ageKeys;
    SOPS_KEY_FILE = config.sops.age.keyFile;
    INSTALL_DISK = config.disko.devices.disk.main.device;
    DISK_PASSWORD_FILE = partitions.ROOT.content.passwordFile;
    SWAP_KEY = swapKey;
    SWAP_KEY_SOURCE = toString config.boot.initrd.secrets.${swapKey};
    ROOT_DEVICE = config.boot.initrd.luks.devices.rootfs.device;
    GAMES_DIR = gamesDir;
  };

  exports = lib.concatStrings (
    lib.mapAttrsToList (n: v: "export ${n}=${lib.escapeShellArg v}\n") vals
  );
  includes = lib.concatMapStringsSep " " (p: "--include ${lib.escapeShellArg p}") preInstallRestore;
in
{
  assertions = [
    {
      assertion = repoParts != null;
      message = "bootstrap.nix: restic repository '${backup.repository}' isn't sftp:<user>@<host>:<path>.";
    }
    {
      assertion = builtins.all backedUp preInstallRestore;
      message = "bootstrap.nix: every pre-install restore path must be under the backup's paths (backup.nix).";
    }
    {
      assertion = config.boot.initrd.luks.devices.swap.keyFile == swapKey;
      message = "bootstrap.nix: disko formats swap with ${swapKey}, but the initrd unlocks it with ${toString config.boot.initrd.luks.devices.swap.keyFile}.";
    }
    {
      assertion = config.fileSystems ? ${gamesDir};
      message = "bootstrap.nix: no filesystem at ${gamesDir}, which the restore leaves out.";
    }
    {
      assertion = builtins.pathExists ageKeys;
      message = "bootstrap.nix: ${ageKeys} is missing from nix-secrets.";
    }
  ];

  system.build.bootstrapEnv = ''
    ${exports}PRE_INSTALL_INCLUDES=(${includes})
    printf '%s\n' "Values from this config (hosts/personal/gibson/bootstrap.nix):"
    for v in ${lib.concatStringsSep " " (lib.attrNames vals)}; do
      printf '  %-22s %s\n' "$v" "''${!v}"
    done
    printf '  %-22s %s\n' PRE_INSTALL_INCLUDES "''${PRE_INSTALL_INCLUDES[*]}"
  '';
}
