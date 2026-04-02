_: {
  flake.modules.homeManager.zsh = _: {
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;

      sessionVariables = {
        GNUMAKEFLAGS = "-j12";
        LESSHISTFILE = "-";
      };

      initContent = ''
        vim() {
          emacsclient -t "$@"
        }
      '';

      oh-my-zsh = {
        enable = true;
        theme = "gentoo";
        plugins = [
          "sudo"
          "git"
          "vi-mode"
          "git-auto-fetch"
        ];
      };
    };
  };
}
