#!/usr/bin/env bash
# Generic deploy entry point for any server host with secrets delivered via
# a plain file over SSH (not sops-nix — see hosts/servers/*/system.nix for
# why). Usage: bootstrap/deploy.sh <host>
#
# Host-specific detail lives in bootstrap/servers/<host>.sh, which must
# define TARGET (root@<ip>) and may define a push_secrets() function run
# before the rebuild. Everything else here is shared mechanics, lifted
# unchanged from what deploy-attic.sh already proved out.
set -euo pipefail

HOST="${1:?usage: bootstrap/deploy.sh <host>}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
  # macOS can't build/execute x86_64-linux directly, so evaluation stays local
  # and only the build step delegates to the target.
  EXTRA_REBUILD_ARGS+=(--no-reexec --build-host "$TARGET")
fi

echo "==> building + switching .#${HOST} on ${TARGET}"
nixos-rebuild switch --flake ".#${HOST}" --target-host "$TARGET" "${EXTRA_REBUILD_ARGS[@]}"
