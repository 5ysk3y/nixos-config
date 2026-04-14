_: {
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

    shellAliases = {
      less = "bat $@";
      ll = "ls -lash";
      ls = "ls --color";
    };

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
}
