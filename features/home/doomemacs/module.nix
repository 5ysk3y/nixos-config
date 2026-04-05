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

        stamp="${config.xdg.stateHome}/doom/sync-stamp"
        key="${emacsPkg}|${inputs.doomemacs}"

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
  })
]
