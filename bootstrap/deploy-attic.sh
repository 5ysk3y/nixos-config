#!/usr/bin/env bash
# Deploys attic from gibson (or any host with nix-secrets access). Never run
# this — or any flake evaluation against .#attic — locally on attic itself;
# see the comment at the top of hosts/attic/system.nix for why.
#
# No sudo anywhere below, deliberately: --target-host activation happens as
# root on attic over SSH, not locally — local sudo isn't just unnecessary
# here, it actively breaks things (env vars/SSH_AUTH_SOCK don't reliably
# survive the hop, and nixos-rebuild is separately aliased to sudo-wrap
# itself on this box — see hosts/gibson/home.nix).
#
# Pushes the atticd env secret out of nix-secrets and over SSH as a plain
# file, root:root 0600. attic gets no age key and no sops-nix module: this
# is the one deliberate exception to "no secrets on this host" — a
# transient plaintext file delivered over an already-trusted channel,
# functionally the same manual step you were doing before, just sourced
# from version control instead of memory.
set -euo pipefail
TARGET="root@192.168.1.110"
# Same resolution flake/lib/mk-vars.nix already does for every other host
# (secretsPath = toString inputs.nix-secrets) — derived from the flake's own
# locked input instead of a separately-maintained env var, so it can't drift
# from what flake.lock actually pins.
SECRETS_PATH="$(nix eval --impure --raw --expr '(builtins.getFlake (toString ./.)).inputs.nix-secrets.outPath')"
SECRETS_FILE="$SECRETS_PATH/secrets/secrets.yaml"
if [ -n "$(git status --porcelain)" ]; then
  echo "error: working tree is dirty — commit first. A switch built from an" >&2
  echo "       uncommitted tree can't be reproduced from git history alone." >&2
  exit 1
fi
# DEPLOY_KEY is passphrase-less on disk by design (root's authorized_keys on
# attic is scoped to just this key; no human is present at automation time
# to type a passphrase). -i reads it directly and never touches any agent —
# deliberately: this box's SSH agent is gpg-agent, which imports anything
# handed to it via ssh-add into its own key store and demands a *separate*
# storage passphrase for it, which is exactly the friction a bare -i avoids.
DEPLOY_KEY="${DEPLOY_KEY:-$HOME/.ssh/deploy}"
if [ -z "${NIX_SSHOPTS:-}" ]; then
  export NIX_SSHOPTS="-i $DEPLOY_KEY"
fi
# shellcheck disable=SC2206 # intentional word-split of a flag string into an array
SSH_OPTS=($NIX_SSHOPTS)
echo "==> pushing atticd env to ${TARGET}"
sops --decrypt --extract '["services"]["attic"]["server-token"]' "$SECRETS_FILE" \
  | ssh "${SSH_OPTS[@]}" "$TARGET" 'install -m 0600 /dev/stdin /var/lib/attic/env'
EXTRA_REBUILD_ARGS=()
if [ "$(uname -s)" = "Darwin" ]; then
  # macOS can't build or execute x86_64-linux directly: --fast skips
  # nixos-rebuild's default self-reexec-for-target-platform step (which is
  # exactly what fails on macOS), and --build-host delegates the actual
  # build to attic itself. Evaluation still happens locally either way —
  # only the build step moves, so this doesn't give attic any new access.
  EXTRA_REBUILD_ARGS+=(--no-reexec --build-host "$TARGET")
fi
echo "==> building + switching .#attic on ${TARGET}"
nixos-rebuild switch --flake ".#attic" --target-host "$TARGET" "${EXTRA_REBUILD_ARGS[@]}"
