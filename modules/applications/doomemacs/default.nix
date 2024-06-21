# ==============================================
# Based on doomemacs's auther's config:
#   https://github.com/hlissner/dotfiles/blob/master/modules/editors/emacs.nix
#
# Emacs Tutorials:
#  1. Official: <https://www.gnu.org/software/emacs/tour/index.html>
#  2. Doom Emacs: <https://github.com/doomemacs/doomemacs/blob/master/docs/index.org>
#
{ config, lib, pkgs, vars, doomemacs, ... }:
with lib; let

  envExtra = ''
    export PATH="${config.xdg.configHome}/emacs/bin:$PATH"
  '';

  myEmacsPackagesFor = emacs: ((pkgs.emacsPackagesFor emacs).emacsWithPackages (epkgs: [
    epkgs.nix-mode
  ]));

in {

  options.applications = {
    doomemacs = mkEnableOption "Doom Emacs Editor";
  };

  config = mkIf config.applications.doomemacs (mkMerge [
    {
      home.packages = with pkgs; [
        ## Doom dependencies
        git
        (ripgrep.override {withPCRE2 = true;})
        gnutls # for TLS connectivity

        ## Optional dependencies
        imagemagick # for image-dired
        fd # faster projectile indexing
        zstd # for undo-fu-session/undo-tree compression

        # go-mode
        # gocode # project archived, use gopls instead

        ## Module dependencies
        # :checkers spell
        #(aspellWithDicts (ds: with ds; [en en-computers en-science]))
        # :tools editorconfig
        #editorconfig-core-c # per-project style config
        # :tools lookup & :lang org +roam
        #sqlite
        # :lang latex & :lang org (latex previews)
        # texlive.combined.scheme-medium
      ];

      programs.zsh.envExtra = envExtra;

      home.file."${config.xdg.configHome}/doom" = {
        source = ./doom;
        recursive = true;
      };

      home.activation.installDoomEmacs = with vars; lib.hm.dag.entryAfter ["writeBoundary"] ''
         ${pkgs.rsync}/bin/rsync -ogavz --chmod=D2755,F744 --chown=${username}:users ${doomemacs}/ ${config.xdg.configHome}/emacs/
      '';
    }

    (mkIf pkgs.stdenv.isLinux (
      let
        # Do not use emacs-nox here, which makes the mouse wheel work abnormally in terminal mode.
        # pgtk (pure gtk) build add native support for wayland.
        # https://www.gnu.org/savannah-checkouts/gnu/emacs/emacs.html#Releases
        emacsPkg = myEmacsPackagesFor pkgs.emacs29-pgtk;
      in {
        home.packages = [emacsPkg];
        services.emacs = {
          enable = true;
          package = emacsPkg;
          client = {
            enable = true;
            arguments = [" --create-frame --tty"];
          };
          startWithUserSession = true;
        };
      }
    ))
  ]);
}
