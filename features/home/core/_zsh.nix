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
        local amend=false
        [[ "$1" == "--amend" || "$1" == "-a" ]] && amend=true

        if $amend && ! git rev-parse --verify HEAD >/dev/null 2>&1; then
          echo "commit-msg --amend: no existing commit to amend" >&2
          return 1
        fi

        local template task rules context msg tmpfile
        template=$(cat "$(git config commit.template)")

        rules="Follow this template, replacing placeholder lines. Output the filled message as plain text — use markdown code fences only for code snippets or references, not for the commit message itself. Do NOT use # comment prefixes on the Why/What/Notes lines, only strip the comment lines from the template itself. Output the commit related context only, in line with the template structure, no preamble or explanation before it.\n\nFormatting rules:\n- Keep the entire first line (type(scope): description) to 72 characters total, including the type and scope.\n- Use imperative mood for the description (e.g. add, fix, refactor), not past tense.\n- Don't capitalize the first letter of the description and don't end it with a period.\n- Omit the scope entirely (no parentheses) if no single aspect, host, or area clearly applies — don't invent one.\n- Leave exactly one blank line between the subject line and the body.\n- Wrap Why/What/Notes body lines at 72 characters. If a '-' bullet wraps to a second line, indent the continuation by 2 spaces so it aligns under the bullet text, not the dash."

        if $amend; then
          local prev_msg
          prev_msg=$(git log -1 --pretty=%B)
          task="This is an amend: the diff below is being folded into the existing commit shown as 'Previous commit message'. Update that message to accurately describe the commit as a whole after the amend — extend the What bullets for the new changes, and only adjust Why/Notes if the new changes actually affect the rationale or caveats. Don't discard accurate parts of the original message just to sound different."
          context=$(printf 'Previous commit message (being amended):\n%s\n\nNewly staged changes to fold in:\nStaged files:\n%s\n\nDiff:\n%s' \
            "$prev_msg" \
            "$(git diff --cached --stat)" \
            "$(git diff --cached)")
        else
          task="Suggest a commit message for these changes."
          context=$(printf 'Staged files:\n%s\n\nDiff:\n%s' \
            "$(git diff --cached --stat)" \
            "$(git diff --cached)")
        fi

        msg=$(printf '%s' "$context" \
          | claude -p "$task $rules\n\n''${template}")

        tmpfile=$(mktemp /tmp/COMMIT_EDITMSG.XXXXXX)
        printf '%s\n\n# Template reference:\n%s\n' "$msg" \
          "$(sed 's/^/# /' <<< "$template")" > "$tmpfile"

        if $amend; then
          git commit --amend -e -F "$tmpfile"
        else
          git commit -e -F "$tmpfile"
        fi

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
