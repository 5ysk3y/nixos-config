{
  config,
  lib,
  pkgs,
  vars,
  hostname,
  ...
}:
let
  flake = "${vars.configDir}#${hostname}";

  # The rebuild command for this platform, minus the action. On NixOS it
  # runs under systemd-inhibit so the machine can't suspend or shut down
  # mid-activation.
  rebuildCmd =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "sudo darwin-rebuild"
    else
      "systemd-inhibit --no-pager --no-legend --mode=block --who='${vars.username}' --why='NixOS Upgrades' sudo nixos-rebuild";

  # Starts attic-push-system (features/services/attic-client) without waiting for
  # it, where the host has it, so a new system reaches the cache straight
  # away rather than at the next timer.
  pushToCache =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "sudo launchctl print system/org.nixos.attic-push-system >/dev/null 2>&1 && sudo launchctl kickstart system/org.nixos.attic-push-system"
    else
      "systemctl cat attic-push-system.service >/dev/null 2>&1 && sudo systemctl start --no-block attic-push-system.service";
in
{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;

    # Keeps zsh's files out of ~: .zshrc and friends in ~/.config/zsh (with
    # a ~/.zshenv that points there), history in ~/.local/share/zsh
    dotDir = "${config.xdg.configHome}/zsh";
    history.path = "${config.xdg.dataHome}/zsh/zsh_history";

    sessionVariables = {
      GNUMAKEFLAGS = "-j12";
      LESSHISTFILE = "-";
    };

    initContent = ''
      cd "${vars.configDir}"

      vim() {
        emacsclient -t "$@"
      }

      bindkey -M viins '\e.' insert-last-word

      # rebuild [action] [args...]: run this host's config from
      # ${vars.configDir} with any rebuild action (switch, boot, build,
      # test, ...), defaulting to switch. Extra args are passed through.
      # After a switch or test, the new system is pushed to attic.
      rebuild() {
        local action="''${1:-switch}"
        (( $# )) && shift
        ${rebuildCmd} "$action" --flake '${flake}' --show-trace "$@" || return
        if [[ $action == (switch|test) ]]; then
          ${pushToCache} || true
        fi
      }

      # commit-msg [--amend|-a]: have Claude fill in .github/gitmessage for the
      # staged changes, open it in the editor, and credit Claude with one
      # Co-authored-by trailer. Only commits made this way get the trailer.
      commit-msg() {
        local amend=false
        [[ "$1" == "--amend" || "$1" == "-a" ]] && amend=true

        if $amend && ! git rev-parse --verify HEAD >/dev/null 2>&1; then
          echo "commit-msg --amend: no existing commit to amend" >&2
          return 1
        fi
        if ! $amend && git diff --cached --quiet; then
          echo "commit-msg: nothing staged" >&2
          return 1
        fi

        local template template_path task context diff msg tmpfile
        local trailer='Co-authored-by: Claude <noreply@anthropic.com>'
        local -a rules
        template_path=$(git config commit.template)
        template_path="''${template_path/#\~/$HOME}"
        template=$(cat "$template_path")

        rules=(
          "Fill in the commit message template below for the staged changes. Output only the commit message, as plain text: no preamble, no code fences around it, and no trailers such as Co-authored-by (one is added for you)."
          ""
          "Subject line: type(scope): summary"
          "- type is one of the template's types."
          "- scope is the host name, the features/ directory name, or the repo area (flake, ci, bootstrap, pkgs, githooks). Reuse a scope from the recent subjects below where one fits; leave out the scope and its parentheses if none does."
          "- Imperative mood, lowercase first letter, no full stop."
          "- Aim for 65 characters or fewer, and never more than 72 in total: GitHub adds the PR number when merging."
          ""
          "Body: one blank line after the subject, every line wrapped at 72 characters, and one blank line between sections. Put each section heading (Why:, What:, Notes:) on a line of its own, as plain text without the template's # markers, with the section's text starting on the next line. Leave out the template's comment lines."
          "- Why: what was wrong or needed, its cause, and why this approach. Don't list the changes here."
          "- What: one bullet per change, naming the option, file or package. Leave the section out when there's a single change the subject already describes. When a bullet wraps, indent the continuation by 2 spaces so it lines up under the text."
          "- Notes: caveats, follow-ups, or what to check before switching (a build, a closure diff) or after. Only suggest checks that apply to this repo's hosts. Leave it out if there's nothing to say."
          "- Don't say the same thing in Why and What."
          "- Describe only what the diff does: don't present code it leaves unchanged as changed, in the subject or the body."
        )

        # flake.lock's diff is all hashes; --stat still lists the file
        diff=$(git diff --cached -- . ':(exclude)flake.lock')

        if $amend; then
          task="This is an amend: the diff below is being folded into the existing commit shown as 'Previous commit message'. Update that message to describe the commit as a whole after the amend: extend the What bullets for the new changes, and only adjust Why/Notes if the new changes affect the rationale or caveats. Don't discard accurate parts of the original message just to sound different."
          context=$(printf 'Previous commit message (being amended):\n%s\n\nNewly staged changes to fold in:\nStaged files:\n%s\n\nDiff:\n%s' \
            "$(git log -1 --pretty=%B)" \
            "$(git diff --cached --stat)" \
            "$diff")
        else
          task="Suggest a commit message for these changes."
          context=$(printf 'Staged files:\n%s\n\nDiff:\n%s' \
            "$(git diff --cached --stat)" \
            "$diff")
        fi
        context=$(printf 'Recent commit subjects:\n%s\n\n%s' \
          "$(git log -20 --format=%s 2>/dev/null)" \
          "$context")

        if ! msg=$(printf '%s' "$context" \
          | claude -p "$task"$'\n\n'"''${(F)rules}"$'\n\n'"$template"); then
          echo "commit-msg: claude failed" >&2
          return 1
        fi
        # One trailer, added below as its own paragraph, whatever Claude wrote
        msg=$(grep -viE '^co-authored-by:.*noreply@anthropic\.com' <<< "$msg" | git stripspace)
        if [[ -z $msg ]]; then
          echo "commit-msg: claude returned no message" >&2
          return 1
        fi

        tmpfile=$(mktemp /tmp/COMMIT_EDITMSG.XXXXXX)
        printf '%s\n\n%s\n\n# Template reference:\n%s\n' "$msg" "$trailer" \
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
      build-nix = "nix-build -E 'with import <nixpkgs> {}; callPackage ./default.nix {}'";
      less = "bat";
      ll = "ls -lash";
      ls = "ls --color";
    }
    # GNU ps and shred, which macOS doesn't have
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      cpu_usage = "ps -eo pid,ppid,%mem,%cpu,cmd --sort=-%cpu | head";
      mem_usage = "ps -eo pid,ppid,%mem,%cpu,cmd --sort=-%mem | head";
      shred = "shred -zfu";
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
