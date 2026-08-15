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

      activation.installDoomEmacs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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

        stamp="${config.xdg.stateHome}/doom/sync-stamp"
        doomcfg_hash=$(find "${config.xdg.configHome}/doom" -type f | sort | xargs sha256sum | sha256sum | cut -d' ' -f1)
        key="${emacsPkg}|${inputs.doomemacs}|${inputs.doomemacs-modules}|$doomcfg_hash"

        if [ ! -f "$stamp" ] || [ "$(cat "$stamp")" != "$key" ]; then
          echo "doom: inputs changed, running doom sync -u --force"
          "${config.xdg.configHome}/emacs/bin/doom" sync -u --force
          echo "$key" > "$stamp"

          ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
            /bin/launchctl kickstart -k gui/$(/usr/bin/id -u)/org.nixos.emacs-daemon || true
          ''}
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

    # installDoomEmacs (above) runs via the system-level
    # home-manager-${username}.service, which has no ordering relative to this
    # user-level emacs.service (WantedBy=default.target).  On a cold boot they
    # race; this will guard against starting before the doomemacs-modules rsync
    # has completed.
    systemd.user.services.emacs.Service.ExecStartPre = [
      "${pkgs.writeShellScript "wait-for-doom-modules" ''
        marker="${config.xdg.configHome}/emacs/sources/doom+/modules/ui/doom/config.el"
        for _ in $(seq 1 30); do
          [ -e "$marker" ] && exit 0
          sleep 1
        done
        echo "wait-for-doom-modules: gave up after 30s waiting for $marker" >&2
        exit 0
      ''}"
    ];
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
      };
    };
  })
]
