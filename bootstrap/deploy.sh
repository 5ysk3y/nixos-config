#!/usr/bin/env bash
# Generic deploy entry point for any server host with secrets delivered via
# a plain file over SSH (not sops-nix — see hosts/servers/*/system.nix for
# why). Usage: bootstrap/deploy.sh <host>|all
#
# Host-specific detail lives in bootstrap/servers/<host>.sh, which must
# define TARGET (root@<ip>) and may define a push_secrets() function that runs
# before the rebuild.
#
# `all` loops over every bootstrap/servers/*.sh and re-invokes this same
# script per host, rather than duplicating the single-host logic — one
# host failing doesn't stop the rest from being attempted, and the exit
# code reflects whether anything failed overall (so CI can act on it).
set -euo pipefail

HOST="${1:?usage: bootstrap/deploy.sh <host>|all}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$HOST" = "all" ]; then
  FAILED=()
  for server_script in "$SCRIPT_DIR"/servers/*.sh; do
    name="$(basename "$server_script" .sh)"
    echo "=== deploying $name ==="
    if ! "$0" "$name"; then
      echo "!!! $name failed, continuing with the rest" >&2
      FAILED+=("$name")
    fi
  done
  if [ "${#FAILED[@]}" -gt 0 ]; then
    echo "error: failed to deploy: ${FAILED[*]}" >&2
    exit 1
  fi
  echo "==> all servers deployed successfully"
  exit 0
fi

SERVER_SCRIPT="$SCRIPT_DIR/servers/$HOST.sh"

if [ ! -f "$SERVER_SCRIPT" ]; then
  echo "error: no bootstrap/servers/$HOST.sh for host '$HOST'" >&2
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "error: working tree is dirty — commit first. A switch built from an" >&2
  echo "       uncommitted tree can't be reproduced from git history alone." >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$SERVER_SCRIPT"
: "${TARGET:?bootstrap/servers/$HOST.sh must set TARGET (root@<ip>)}"

# DEPLOY_KEY is passphrase-less on disk by design (root's authorized_keys on
# the servers is scoped to this key; no human is present at automation time
# to type a passphrase). -i reads it directly and never touches any agent —
# deliberately: the local SSH agent is gpg-agent, which imports anything
# handed to it via ssh-add into its own key store and demands a *separate*
# storage passphrase for it, which is exactly the friction a bare -i avoids.
DEPLOY_KEY="${DEPLOY_KEY:-$HOME/.ssh/deploy}"
if [ -z "${NIX_SSHOPTS:-}" ]; then
  export NIX_SSHOPTS="-i $DEPLOY_KEY"
fi
# shellcheck disable=SC2206
SSH_OPTS=($NIX_SSHOPTS)

if declare -F preflight_check > /dev/null; then
  preflight_check
fi

if declare -F push_secrets > /dev/null; then
  echo "==> pushing secrets to ${TARGET}"
  push_secrets
fi

EXTRA_REBUILD_ARGS=()
if [ "$(uname -s)" = "Darwin" ]; then
  # macOS can't build or execute x86_64-linux directly: --no-reexec skips
  # nixos-rebuild's self-reexec-for-target-platform step (which is exactly
  # what fails on macOS), and --build-host delegates the actual build to the
  # target. Evaluation still happens locally — only the build step moves, so
  # this gives the server no new access.
  EXTRA_REBUILD_ARGS+=(--no-reexec --build-host "$TARGET")
fi

echo "==> building + switching .#${HOST} on ${TARGET}"
nixos-rebuild switch --flake ".#${HOST}" --target-host "$TARGET" "${EXTRA_REBUILD_ARGS[@]}"
