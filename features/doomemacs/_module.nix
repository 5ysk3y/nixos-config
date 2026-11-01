# ==============================================
# Based on doomemacs's author's config:
#   https://github.com/hlissner/dotfiles/blob/master/modules/editors/emacs.nix
#
# Emacs Tutorials:
#  1. Official: <https://www.gnu.org/software/emacs/tour/index.html>
#  2. Doom Emacs: <https://github.com/doomemacs/doomemacs/blob/master/docs/index.org>
#
{
  config,
  lib,
  pkgs,
  vars,
  inputs,
  ...
}:
with lib;
let
  envExtra = ''
    export PATH="${config.xdg.configHome}/emacs/bin:$PATH"
  '';

  rsyncChown = if pkgs.stdenv.hostPlatform.isDarwin then "" else "--chown=${vars.username}:users";

  myEmacsPackagesFor =
    emacs:
    (pkgs.emacsPackagesFor emacs).emacsWithPackages (epkgs: [
      epkgs.nix-mode
      epkgs.lsp-mode
      epkgs.vterm
    ]);

  emacsPkg =
    if pkgs.stdenv.hostPlatform.isLinux then
      myEmacsPackagesFor pkgs.emacs-pgtk
    else
      myEmacsPackagesFor pkgs.emacs;

  emacsDir = "${config.xdg.configHome}/emacs";
  syncStamp = "${config.xdg.stateHome}/doom/sync-stamp";
  hmUnit = "home-manager-${vars.username}.service";
  # The InvocationID of the Home Manager run that last put Doom's files in
  # place (see installDoomEmacs)
  filesReady = "${config.xdg.stateHome}/doom/files-ready";

  # Sets $key to what the last `doom sync` must have been run against; a
  # different key in the stamp file means it's time to sync again. The Doom
  # config is keyed by its store path, which changes whenever any file in it
  # does. (Hashing ~/.config/doom at runtime doesn't work: Home Manager links
  # each file there into the store, and `find -type f` skips symlinks.)
  syncKey = ''
    key="${emacsPkg}|${inputs.doomemacs}|${inputs.doomemacs-modules}|${./doom}"
  '';

  # installDoomEmacs (below) runs via the system-level ${hmUnit}, which has
  # no ordering relative to user-level units, and with linger the user
  # manager starts at boot alongside it. On a cold boot they race; this
  # guards against starting before the doomemacs-modules rsync has completed.
  #
  # Home Manager itself (re)starts units while still activating, after the
  # rsync: the files-ready marker holding the running activation's
  # InvocationID says so, rather than waiting on an activation that's
  # waiting on us.
  waitForHomeManager = pkgs.writeShellScript "wait-for-home-manager-activation" ''
    systemctl=${pkgs.systemd}/bin/systemctl
    for _ in $(seq 1 60); do
    state=$($systemctl show -p ActiveState --value ${hmUnit} 2>/dev/null || echo unknown)
    [ "$state" = "active" ] && exit 0
    if [ "$state" = "activating" ] && [ -s "${filesReady}" ] &&
      [ "$(cat "${filesReady}")" = "$($systemctl show -p InvocationID --value ${hmUnit} 2>/dev/null)" ]; then
      exit 0
    fi
    sleep 1
    done
    echo "wait-for-home-manager-activation: ${hmUnit} not active after 60s (state=$state)" >&2
    exit 0
  '';

  # Installs Doom's packages when they're missing entirely (a restore or a
  # fresh install: the backup leaves .local/straight out). Cloning and
  # compiling every package needs the network and takes several minutes, too
  # long for activation at boot, so it runs as a user service after login,
  # then starts Emacs.
  doomSync = pkgs.writeShellScript "doom-sync" ''
    set -euo pipefail
    # Here rather than in ExecStartPre, so the wait doesn't hold up the
    # service's start (see doom-sync below)
    ${waitForHomeManager}

    export DOOMDIR="${config.xdg.configHome}/doom"
    export EMACSDIR="${emacsDir}"
    export PATH="${config.home.profileDirectory}/bin:/run/current-system/sw/bin:${emacsDir}/bin:$PATH"

    # A desktop notification, once a notification daemon is up (waiting up
    # to $1 seconds): this starts at login, before the desktop session has
    # started one. Waiting, rather than letting notify-send start one over
    # D-Bus, keeps the daemon in the session.
    notify() {
      local wait=$1
      shift
      ${pkgs.glib}/bin/gdbus wait --session --timeout "$wait" org.freedesktop.Notifications >/dev/null 2>&1 &&
        ${pkgs.libnotify}/bin/notify-send --app-name="Doom Emacs" "$@" || true
    }

    notify 120 "Installing Doom Emacs packages" "Emacs starts once this finishes, in several minutes." &

    # User units can't wait for network-online.target: wait for GitHub,
    # where most packages come from, for up to ~10 minutes.
    for _ in $(seq 60); do
      timeout 5 ${lib.getExe pkgs.bash} -c '</dev/tcp/github.com/443' 2>/dev/null && break
      sleep 5
    done

    if ! "$EMACSDIR/bin/doom" sync -u --force; then
      notify 10 --urgency=critical "Doom Emacs packages failed to install" \
        "See: journalctl --user -u doom-sync"
      exit 1
    fi

    ${syncKey}
    mkdir -p "$(dirname "${syncStamp}")"
    echo "$key" > "${syncStamp}"

    notify 10 "Doom Emacs packages installed" "Emacs is starting."
    ${pkgs.systemd}/bin/systemctl --user start emacs.service ||
      echo "doom-sync: emacs.service failed to start" >&2
  '';
in
mkMerge [
  {
    home = {
      packages = with pkgs; [
        emacsPkg
        git
        (ripgrep.override { withPCRE2 = true; })
        gnutls
        imagemagick
        fd
        zstd
        cmake
        gnumake
      ];

      file."${config.xdg.configHome}/doom" = {
        source = ./doom;
        recursive = true;
      };

      # Before reloadSystemd, where Home Manager (re)starts user units, so
      # Doom's files (and the files-ready marker) are in place by then
      activation.installDoomEmacs =
        lib.hm.dag.entryBetween [ "reloadSystemd" "setupLaunchAgents" ] [ "writeBoundary" ]
          ''
            set -euo pipefail

            export DOOMDIR="${config.xdg.configHome}/doom"
            export EMACSDIR="${config.xdg.configHome}/emacs"
            export PATH="${config.home.profileDirectory}/bin:${config.xdg.configHome}/emacs/bin:$PATH"

            mkdir -p "${config.xdg.configHome}"
            mkdir -p "${config.xdg.stateHome}/doom"

            ${pkgs.rsync}/bin/rsync -ogav --delete \
              --exclude '.local' --exclude '.cache' \
              --chmod=D2755,F744 ${rsyncChown} \
              ${inputs.doomemacs}/ "$EMACSDIR/"

            mkdir -p "$EMACSDIR/sources/doom+"
            ${pkgs.rsync}/bin/rsync -ogav --delete \
              --chmod=D2755,F744 ${rsyncChown} \
              ${inputs.doomemacs-modules}/ "$EMACSDIR/sources/doom+/"

            ${lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
              # For waitForHomeManager: this activation's files are in place
              ${pkgs.systemd}/bin/systemctl show -p InvocationID --value ${hmUnit} > "${filesReady}" || true
            ''}
            stamp="${syncStamp}"
            ${syncKey}

            # Packages missing entirely (a restore or a fresh install): on Linux,
            # doom-sync.service installs them after login, since a full sync is
            # too long for activation at boot. Elsewhere, sync here as usual.
            defer_to_service="${lib.optionalString pkgs.stdenv.hostPlatform.isLinux "1"}"

            if [ -n "$defer_to_service" ] && [ ! -d "$EMACSDIR/.local/straight" ]; then
              echo "doom: packages missing, leaving the sync to doom-sync.service"
            elif [ ! -f "$stamp" ] || [ "$(cat "$stamp")" != "$key" ] || [ ! -d "$EMACSDIR/.local/straight" ]; then
              echo "doom: inputs changed, running doom sync -u --force"
              "${config.xdg.configHome}/emacs/bin/doom" sync -u --force
              echo "$key" > "$stamp"

              ${lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
                systemctl --user restart emacs || true
              ''}
            else
              echo "doom: inputs unchanged, skipping doom sync"
            fi
          '';
    };

    programs.zsh.envExtra = envExtra;
  }

  (mkIf pkgs.stdenv.hostPlatform.isLinux {
    services.emacs = {
      enable = true;
      package = emacsPkg;
      client = {
        enable = true;
        arguments = [ " --create-frame --tty" ];
      };
      startWithUserSession = true;
    };

    systemd.user.services = {
      emacs = {
        # Skipped while Doom's packages are missing; doom-sync starts it
        # once they're installed
        Unit.ConditionPathExists = "${emacsDir}/.local/straight";
        Service.ExecStartPre = [ "${waitForHomeManager}" ];
      };

      doom-sync = {
        Unit = {
          Description = "Install Doom Emacs packages after a restore or fresh install";
          # Otherwise installDoomEmacs keeps them in sync at activation
          ConditionPathExists = "!${emacsDir}/.local/straight";
        };
        Service = {
          # Started as soon as the script runs, not once the sync is done:
          # Home Manager's activation starts this unit and waits for the
          # start to finish, so a oneshot here would hold activation (and
          # home-manager-${username}.service's 5-minute timeout) for the
          # whole sync
          Type = "exec";
          # For notify-send: the user bus, in the user's runtime directory
          Environment = [ "DBUS_SESSION_BUS_ADDRESS=unix:path=%t/bus" ];
          ExecStart = "${doomSync}";
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
  })

  (mkIf pkgs.stdenv.hostPlatform.isDarwin {
    launchd.agents.emacs-daemon = {
      enable = true;
      config = {
        ProgramArguments = [
          "${emacsPkg}/bin/emacs"
          "--fg-daemon"
        ];
        EnvironmentVariables = {
          PATH = lib.concatStringsSep ":" [
            "/etc/profiles/per-user/${vars.username}/bin"
            "/run/current-system/sw/bin"
            "/nix/var/nix/profiles/default/bin"
            "/usr/bin"
            "/bin"
            "/usr/sbin"
            "/sbin"
          ];
          TERMINFO_DIRS = lib.concatStringsSep ":" [
            "${pkgs.ghostty-bin.terminfo}/share/terminfo"
            "${pkgs.ncurses.out}/share/terminfo"
            "/usr/share/terminfo"
            "/etc/terminfo"
          ];
        };
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/tmp/emacs-daemon.log";
        StandardErrorPath = "/tmp/emacs-daemon.err";
        restartTriggers = [
          inputs.doomemacs
          inputs.doomemacs-modules
          ./doom
        ];
      };
    };
  })
]
