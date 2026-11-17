# Claude Code, CLI and the desktop app's Code tab alike: both read
# ~/.claude/settings.json, written here read-only, so a session can't
# loosen these rules for itself.
#
# Secrets are hidden two ways:
#   - permissions.deny Read/Edit rules stop Claude's file tools, and shell
#     commands it recognises (cat, head, sed, redirections...).
#   - the Bash sandbox, which adds every Read deny rule to its denyRead
#     list, blocks the same paths for every process a sandboxed command
#     starts, scripts included.
# Neither covers a command you approve to run outside the sandbox, so read
# such prompts before allowing them.
{
  config,
  lib,
  pkgs,
  vars,
  osConfig,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
  inherit (config.home) homeDirectory;
  inherit (config.xdg)
    cacheHome
    configHome
    dataHome
    stateHome
    ;
  appSupport = "${homeDirectory}/Library/Application Support";

  # Directories holding secrets, keys or credentials, and everything in them
  secretDirs = [
    # sops: the age key that decrypts all of nix-secrets, the sops CLI's own
    # key location, and Home Manager's decrypted secrets (symlinks into the
    # runtime directory below)
    (dirOf vars.age.keyFile)
    "${configHome}/sops"
    "${configHome}/sops-nix"

    # pass's store and the main store's private key (synced by Syncthing)
    "${dataHome}/pass"
    "${vars.syncthingPath}/Files/nix/gnupg"

    # rbw (Bitwarden CLI): its sops-written config, vault cache and agent
    "${configHome}/rbw"
    "${cacheHome}/rbw"
    "${dataHome}/rbw"
  ]
  ++ lib.optionals isLinux [
    # sops-nix: system secrets, and Home Manager's decrypted secrets
    "/run/secrets"
    "/run/secrets.d"
    "/run/secrets-for-users"
    "/run/user/${toString osConfig.users.users.${vars.username}.uid}/secrets.d"

    # Syncthing's device key and API key (copied there from sops)
    "${stateHome}/syncthing"

    # Login sessions and tokens: desktop keyring (Claude Desktop's sign-in
    # lives here), browser profile, Bitwarden, messaging apps
    "${dataHome}/keyrings"
    "${dataHome}/qutebrowser"
    "${configHome}/Bitwarden"
    "${configHome}/Signal"
    "${configHome}/discord"
  ]
  ++ lib.optionals isDarwin [
    "${appSupport}/Syncthing"
    "${appSupport}/qutebrowser"
    "${appSupport}/Bitwarden"
    "${appSupport}/Signal"
    "${appSupport}/discord"
  ];

  # Single files holding credentials
  secretFiles = [
    # jellyfin-mpv-shim's login, written by sops (features/apps/media)
    "${configHome}/jellyfin-mpv-shim/cred.json"
    # Claude Code's own OAuth credentials
    "${homeDirectory}/.claude/.credentials.json"
    # Shell history: anything ever typed or pasted at a prompt
    "${dataHome}/zsh/zsh_history"
  ];

  # Readable, but not writable: changing these would let a session widen
  # its own access (SSH and GPG config, known_hosts, trust)
  protectedDirs = [
    "${homeDirectory}/.ssh"
    "${homeDirectory}/.gnupg"
  ];

  # Permission rules take absolute paths as //path; every path above starts
  # with /, so prefixing one more makes it absolute
  dirRule = tool: dir: "${tool}(/${dir}/**)";
  fileRule = tool: file: "${tool}(/${file})";
in
{
  # claude-code itself comes from the claude-code-nix overlay, applied by
  # this feature's nixos/darwin modules (see default.nix) via the system
  # profiles. Its wrapper puts bubblewrap and socat, the sandbox's Linux
  # dependencies, on PATH.
  programs = {
    claude-code = {
      enable = true;

      # Loaded in every local session, whatever the repo
      rules.commit-messages = ''
        # Commit messages and PR descriptions

        - Never link or reference PRs or issues in a way GitHub turns into a
          link: no `#123`, no `owner/repo#123`, no `GH-123`, and no github.com
          URLs to PRs, issues or commits. Each one adds a cross-reference to
          the target and makes noise.
        - When the history matters, describe it in words ("the earlier
          HYPRLAND_NO_RT workaround") or name an upstream change in plain text
          with no `#` ("nixpkgs PR 586820").
        - The `(#123)` GitHub appends to a squash-merged subject is fine:
          GitHub adds it, so don't write it yourself.

        ## Style

        - Write for someone who hasn't read the diff: say what a thing is
          before what was wrong with it, and don't leave them to connect
          the dots.
        - Why is a short story in two to four sentences: the problem, then
          how this change fixes it. Each sentence follows from the one
          before. Never state a fact without saying why it matters.
        - Side fixes go in What as bullets, not in Why.
        - One idea per sentence, in plain words. Don't chain clauses with
          colons, semicolons or "so".
        - What bullets are short, ideally one line: the option, file or
          package, then the change in plain words.
        - Leave out anything a reader would delete: how the change was
          verified, internal mechanics, restatements.
        - Notes holds only what someone needs before or after switching,
          in a sentence or two.
      '';

      settings = {
        permissions.deny =
          map (dirRule "Read") secretDirs
          ++ map (dirRule "Edit") secretDirs
          ++ map (fileRule "Read") secretFiles
          ++ map (fileRule "Edit") secretFiles
          ++ map (dirRule "Edit") protectedDirs;

        sandbox = {
          enabled = true;
          # Refuse to start rather than quietly run commands unsandboxed
          failIfUnavailable = true;
          # The Nix evaluation cache, which nix eval and nix build write to
          filesystem.allowWrite = [ "~/.cache/nix" ];
          # Evaluating or building this repo's flake can't work sandboxed on
          # Linux: the seccomp filter blocks the nix-daemon's Unix socket, and
          # the placeholder the sandbox mounts over the protected .gitmodules
          # breaks git flake fetching. These run unsandboxed (builds are
          # still sandboxed by the daemon) but keep their permission prompts.
          # `nix run` and `nix develop` are left out: they execute code.
          excludedCommands = [
            "nix eval *"
            "nix build *"
            "nix flake check *"
            "nix flake show *"
            "nix flake metadata *"
            "nix fmt *"
          ];
        };
      };
    };
  };
}
