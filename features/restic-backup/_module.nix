# Restic backups that also record failures in a status file for Zabbix to
# monitor. Import by name (inputs.self.modules.nixos.restic-backup) and
# declare each backup under features.system.resticBackups.<name>.
{ config, lib, ... }:
let
  cfg = config.features.system.resticBackups;
  inherit (lib) mkOption types;
in
{
  options.features.system.resticBackups = mkOption {
    default = { };
    description = "Restic backups, each with a Zabbix-watched status file that records failures.";
    type = types.attrsOf (
      types.submodule {
        options = {
          paths = mkOption { type = types.listOf types.str; };
          repository = mkOption { type = types.str; };
          passwordFile = mkOption { type = types.str; };
          extraOptions = mkOption {
            type = types.listOf types.str;
            default = [ ];
          };
          extraBackupArgs = mkOption {
            type = types.listOf types.str;
            default = [ ];
          };
          backupPrepareCommand = mkOption {
            type = types.nullOr types.lines;
            default = null;
            description = "Runs after the status file is truncated, before the backup.";
          };
          timerConfig = mkOption {
            type = types.attrsOf types.anything;
            default = {
              OnCalendar = "2:30";
            };
          };
          pruneOpts = mkOption {
            type = types.listOf types.str;
            default = [
              "--keep-daily 7"
              "--keep-weekly 4"
              "--keep-monthly 6"
            ];
          };
          statusFile = mkOption {
            type = types.str;
            default = "/var/log/restic_backup_local.log";
            description = "The path Zabbix watches for this backup's status.";
          };
        };
      }
    );
  };

  config = lib.mkIf (cfg != { }) {
    assertions = [
      {
        assertion = lib.allUnique (lib.mapAttrsToList (_: b: b.statusFile) cfg);
        message = "features.system.resticBackups: each backup needs its own statusFile, or they overwrite each other's status.";
      }
    ];

    services.restic.backups = lib.mapAttrs (_: b: {
      inherit (b)
        paths
        repository
        passwordFile
        extraOptions
        extraBackupArgs
        timerConfig
        pruneOpts
        ;
      # Status file truncated first, before any caller-supplied
      # prepare step — if that step itself fails, onFailure below
      # still fires and overwrites with "local failure" regardless,
      # but truncating first keeps the intent readable: this run's
      # status starts clean before anything else happens.
      backupPrepareCommand =
        ": > ${b.statusFile}"
        + lib.optionalString (b.backupPrepareCommand != null) ("\n" + b.backupPrepareCommand);
    }) cfg;

    systemd = {
      tmpfiles.rules = lib.mapAttrsToList (_: b: "f ${b.statusFile} 0644 root root -") cfg;
      services = lib.concatMapAttrs (name: b: {
        "restic-backups-${name}".onFailure = [
          "restic-backup-failure-${name}.service"
        ];
        "restic-backup-failure-${name}" = {
          description = "Records restic backup failure for Zabbix monitoring (${name})";
          serviceConfig.Type = "oneshot";
          script = ''
            echo "local failure" > ${b.statusFile}
          '';
        };
      }) cfg;
    };
  };
}
