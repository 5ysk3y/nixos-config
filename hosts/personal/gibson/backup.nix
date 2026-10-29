# Restic backup of gibson's state that Nix doesn't rebuild.
#
# Everything under `paths` is backed up unless `exclude` matches it, so data a
# new app writes is covered without editing this file. Exclusions are limited
# to things that are rebuilt, re-downloaded or cached, plus /var/lib/age (the
# sops key, restored from a YubiKey instead).
#
# The games disk (~/games) is a separate filesystem: --one-file-system keeps
# the walk of the home directory from descending into it, while the save
# folders listed explicitly below are still backed up (restic checks each file
# against the device of the path it was reached from).
{
  config,
  inputs,
  lib,
  pkgs,
  vars,
  ...
}:
let
  home = "/home/${vars.username}";
  backupHost = "backupServer.home.arpa";
  sftpKey = config.sops.secrets.restic-sftp-key.path;
in
{
  imports = [ inputs.self.modules.nixos.restic-backup ];

  sops.secrets = {
    restic-password = {
      format = "binary";
      sopsFile = "${vars.secretsPath}/secrets/gibson/restic.password";
    };

    restic-sftp-key = {
      format = "binary";
      sopsFile = "${vars.secretsPath}/secrets/restic/sftp.key";
    };
  };

  # Pinned so the backup never accepts an unverified host key.
  programs.ssh.knownHosts.${backupHost}.publicKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPF26LRZNEBi4ufLCnxehiKa26R5JBh3+JIUop4C6MtH";

  features.system.resticBackups.gibson = {
    repository = "sftp:networkBackup@${backupHost}:Linux/gibson";
    backupPrepareCommand = ''
      for _ in $(seq 40); do
        timeout 2 ${lib.getExe pkgs.bash} -c '</dev/tcp/${backupHost}/22' 2>/dev/null && exit 0
        sleep 1
      done
      echo "backup server ${backupHost} unreachable" >&2
      exit 1
    '';
    passwordFile = config.sops.secrets.restic-password.path;
    extraOptions = [
      "sftp.command='ssh networkBackup@${backupHost} -i ${sftpKey} -o StrictHostKeyChecking=yes -s sftp'"
    ];
    extraBackupArgs = [
      "--one-file-system"
      "--exclude-caches"
      "--tag nix"
    ];
    # gibson is often off or asleep: missed runs happen at next boot
    # (Persistent, from the feature's default timerConfig), and sleep is
    # blocked while a run is in progress.
    inhibitsSleep = true;
    notifyUser = vars.username;

    paths = [
      home
      "/root"
      "/var/lib"
      "/etc/secrets"
      "/etc/ssh"
      "/etc/machine-id"
      "/etc/NetworkManager/system-connections"

      # Game saves on the games disk: the user folders of every Wine/Proton
      # prefix (Heroic prefixes can have both layouts, from Wine and Proton
      # runs). About 5.8G in all, before deduplication.
      "${home}/games/SteamLibrary/steamapps/compatdata/*/pfx/drive_c/users"
      "${home}/games/heroic/Prefixes/default/*/drive_c/users"
      "${home}/games/heroic/Prefixes/default/*/pfx/drive_c/users"
    ];

    exclude = [
      # Caches and rebuilt state
      "${home}/Downloads/ISO*"
      "${home}/.cache"
      "${home}/.nv"
      "/root/.cache"
      "${home}/.config/emacs/*" # Doom's checkout, re-synced from Nix
      "!${home}/.config/emacs/.local"
      "${home}/.config/emacs/.local/straight" # packages, rebuilt by doom sync
      "${home}/.config/emacs/.local/cache/eln" # native-compiled code
      "${home}/.config/emacs/.local/cache/comp"
      "${home}/.wine" # user folders are empty; nothing in it is user data

      # Chat/music clients: caches plus a login
      "${home}/.config/discord"
      "${home}/.config/discord.broken.*"
      "${home}/.config/sh.cider.genten"
      "${home}/.config/sh.cider.genten.bak"

      # Heroic: Wine/Proton builds and web caches (configs and logins kept)
      "${home}/.config/heroic/tools"
      "${home}/.config/heroic/Partitions"
      "${home}/.config/heroic/Cache"
      "${home}/.config/heroic/Code Cache"
      "${home}/.config/heroic/GPUCache"
      "${home}/.config/heroic/Dawn*"
      "${home}/.config/heroic/images-cache"
      "${home}/.config/heroic/icons"
      "${home}/.config/heroic/store_cache"
      "${home}/.config/heroic/Service Worker"
      "${home}/.config/heroic/logs"

      # Steam: only settings, userdata, app manifests and Proton prefixes
      "${home}/.local/share/Steam/*"
      "!${home}/.local/share/Steam/userdata"
      "!${home}/.local/share/Steam/config"
      "!${home}/.local/share/Steam/steamapps"
      "${home}/.local/share/Steam/steamapps/*"
      "!${home}/.local/share/Steam/steamapps/compatdata"
      "!${home}/.local/share/Steam/steamapps/*.acf"

      # Launchers: runners, runtimes and downloads (configs kept)
      "${home}/.local/share/lutris/runners"
      "${home}/.local/share/lutris/runtime"
      "${home}/.local/share/lutris/covers"
      "${home}/.local/share/bottles/runners"
      "${home}/.local/share/bottles/templates"
      "${home}/.local/share/bottles/temp"
      "${home}/.local/share/bottles/runtimes"
      "${home}/.local/share/bottles/dxvk"
      "${home}/.local/share/bottles/vkd3d"
      "${home}/.local/share/bottles/nvapi"
      "${home}/.local/share/bottles/latencyflex"
      "${home}/.local/share/bottles/winebridge"
      "${home}/.local/share/dev.goats.xivlauncher/compatibilitytool"
      "${home}/.local/share/dev.goats.xivlauncher/runtime"
      "${home}/.local/share/dev.goats.xivlauncher/dalamud"
      "${home}/.local/share/dev.goats.xivlauncher/dalamudAssets"
      "${home}/.local/share/dev.goats.xivlauncher/protonprefix"
      "${home}/.local/share/dev.goats.xivlauncher/wineprefix"
      "${home}/.local/share/dev.goats.xivlauncher/logs"
      "${home}/.local/share/dev.goats.xivlauncher/patch"
      "${home}/.local/share/dev.goats.xivlauncher/temp"
      "${home}/.local/share/umu"
      "${home}/.local/share/NuGet"
      "${home}/.local/share/virtualenv"
      "${home}/.local/share/comet"
      "${home}/.local/share/steam-default.log"

      # Wine/Proton prefixes: keep user folders, drop the Windows install.
      # Must come after the Steam block: restic applies patterns in order, so
      # its "!…/compatdata" re-include would otherwise cancel these.
      "**/drive_c/windows"
      "**/drive_c/Program Files"
      "**/drive_c/Program Files (x86)"
      "**/drive_c/users/*/AppData/Local/Temp"
      "**/drive_c/users/*/AppData/Local/NVIDIA"
      "**/drive_c/users/*/AppData/Local/D3DSCache"

      # System
      "/var/lib/age" # sops master key: restored from a YubiKey, never backed up
      "/var/lib/systemd/coredump"
      "/var/lib/systemd/pstore"
      "/var/lib/flatpak" # flatpak isn't enabled in this config
      "/var/lib/libvirt/images"
      "/var/lib/libvirt/qemu/ram"
    ];
  };
}
