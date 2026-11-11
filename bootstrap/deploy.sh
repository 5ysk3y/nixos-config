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

# For push_secrets(): write stdin to <dest> on $TARGET as a root-only file,
# creating its directory if needed. If the content changed and <unit> is
# given, try-restart it (a restart only if it's running), so the service
# picks up a rotated secret even when the switch below leaves the unit
# itself unchanged.
push_secret() {
  local dest="$1" unit="${2:-}" remote
  read -r -d '' remote <<'REMOTE' || true
set -eu
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
cat >"$tmp"
mkdir -p -m 0700 "$(dirname "$dest")"
if ! cmp -s "$tmp" "$dest"; then
  install -m 0600 "$tmp" "$dest"
  echo "    updated $dest"
  if [ -n "$unit" ]; then
    systemctl try-restart "$unit"
  fi
fi
REMOTE
  # shellcheck disable=SC2029 # dest/unit are meant to expand here, %q-quoted
  ssh "${SSH_OPTS[@]}" "$TARGET" "dest=$(printf '%q' "$dest"); unit=$(printf '%q' "$unit"); $remote"
}

# shellcheck source=/dev/null
source "$SERVER_SCRIPT"
: "${TARGET:?bootstrap/servers/$HOST.sh must set TARGET (root@<ip>)}"

# SSH authenticates with the YubiKey through gpg-agent: root's
# authorized_keys on the servers holds both YubiKeys' keys
# (features/core/ssh-keys). Expect a PIN prompt or a touch per connection.
# DEPLOY_KEY=<file> uses a key file instead, with -i so the file never
# reaches gpg-agent (which would import it and ask for a passphrase to
# store it under).
if [ -z "${NIX_SSHOPTS:-}" ]; then
  if [ -n "${DEPLOY_KEY:-}" ]; then
    export NIX_SSHOPTS="-i $DEPLOY_KEY"
  elif [ -n "${SSH_AUTH_SOCK:-}" ]; then
    # Named explicitly so SSH_OPTS below is never empty, which bash 3.2
    # (macOS's /bin/bash) treats as unbound under set -u
    export NIX_SSHOPTS="-o IdentityAgent=$SSH_AUTH_SOCK"
  else
    echo "error: SSH_AUTH_SOCK isn't set, so gpg-agent can't offer the YubiKey;" >&2
    echo "       start a new login shell, or set DEPLOY_KEY=<key file>" >&2
    exit 1
  fi
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
