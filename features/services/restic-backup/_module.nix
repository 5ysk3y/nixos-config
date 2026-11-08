# Restic backups, checked after every run, that also record failures in a
# status file for Zabbix to monitor. Import by name
# (inputs.self.modules.nixos.restic-backup) and declare each backup under
# features.system.resticBackups.<name>.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.system.resticBackups;
  inherit (lib) mkOption types;

  # Run as the user, against their session bus. Waits briefly for a
  # notification daemon rather than letting notify-send start one outside
  # the desktop session.
  notifyFailure = pkgs.writeShellScript "restic-notify-failure" ''
    ${pkgs.glib}/bin/gdbus wait --session --timeout 10 org.freedesktop.Notifications >/dev/null 2>&1 &&
      ${pkgs.libnotify}/bin/notify-send --app-name=restic --urgency=critical "$1" "$2"
  '';
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
          exclude = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Patterns excluded from the backup, one restic exclude pattern per entry.";
          };
          inhibitsSleep = mkOption {
            type = types.bool;
            default = false;
            description = "Block suspend and hibernate while the backup runs, for hosts that sleep.";
          };
          backupPrepareCommand = mkOption {
            type = types.nullOr types.lines;
            default = null;
            description = "Runs after the status file is truncated, before the backup.";
          };
          timerConfig = mkOption {
            type = types.attrsOf types.anything;
            # Replaces services.restic's default wholesale, so Persistent has
            # to be restated or a run missed while the host was down never
            # happens.
            default = {
              OnCalendar = "2:30";
              Persistent = true;
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
          checkOpts = mkOption {
            type = types.listOf types.str;
            default = [ "--read-data-subset=5%" ];
            description = ''
              Options for the `restic check` run after every backup and prune.
              A failed check fails the backup unit, so it's recorded in the
              status file like any other failure. The default re-reads a
              random 5% of the repository's data each run; [ ] disables the check.
            '';
          };
          statusFile = mkOption {
            type = types.str;
            default = "/var/log/restic_backup_local.log";
            description = "The path Zabbix watches for this backup's status.";
          };
          notifyUser = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              A user to send a desktop notification to when this backup
              fails. Skipped when they have no session running; it never
              affects the backup or the status file.
            '';
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
        exclude
        inhibitsSleep
        timerConfig
        pruneOpts
        ;
      # services.restic puts these straight into ExecStart, where systemd
      # reads "%" as a specifier; "%%" is how a literal "%" gets through.
      checkOpts = map (lib.replaceStrings [ "%" ] [ "%%" ]) b.checkOpts;
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
        "restic-backups-${name}" = {
          onFailure = [
            "restic-backup-failure-${name}.service"
          ];
          # A run that fell due during sleep starts on resume, while logind
          # still refuses sleep inhibitors ("The operation inhibition has
          # been requested for is already running"), so systemd-inhibit fails
          # the run before restic starts. Waiting for the sleep job to finish
          # first lets the inhibitor through.
          after = lib.optionals b.inhibitsSleep [
            "suspend.target"
            "hibernate.target"
            "hybrid-sleep.target"
            "suspend-then-hibernate.target"
          ];
        };
        "restic-backup-failure-${name}" = {
          description = "Records restic backup failure for Zabbix monitoring (${name})";
          serviceConfig.Type = "oneshot";
          script = ''
            echo "local failure" > ${b.statusFile}
          ''
          + lib.optionalString (b.notifyUser != null) ''
            bus="/run/user/$(id -u ${b.notifyUser})/bus"
            if [ -S "$bus" ]; then
              ${pkgs.util-linux}/bin/runuser -u ${b.notifyUser} -- \
                env DBUS_SESSION_BUS_ADDRESS="unix:path=$bus" ${notifyFailure} \
                "Backup failed: ${name}" "See: sudo journalctl -u restic-backups-${name}" || true
            fi
          '';
        };
      }) cfg;
    };
  };
}
