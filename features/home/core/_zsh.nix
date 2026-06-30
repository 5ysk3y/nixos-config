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

      commit-msg() {
        local template msg tmpfile
        template=$(cat "$(git config commit.template)")
        msg=$(printf 'Staged files:\n%s\n\nDiff:\n%s' \
          "$(git diff --cached --stat)" \
          "$(git diff --cached)" \
          | claude -p "Suggest a commit message for these changes. Follow this template, replacing placeholder lines. Output the filled message as plain text — use markdown code fences only for code snippets or references, not for the commit message itself. Do NOT use # comment prefixes on the Why/What/Notes lines, only strip the comment lines from the template itself. Output the commit related context only, in line with the template structure, no preamble or explanation before it:\n\n''${template}")
          tmpfile=$(mktemp /tmp/COMMIT_EDITMSG.XXXXXX)
          printf '%s\n\n# Template reference:\n%s\n' "$msg" \
            "$(sed 's/^/# /' <<< "$template")" > "$tmpfile"
          git commit -e -F "$tmpfile"
          rm -f "$tmpfile"
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
