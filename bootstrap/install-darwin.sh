#!/usr/bin/env bash
# bootstrap/install-darwin.sh — nix-darwin (macOS) bootstrap
#
# Bootstraps a fresh macOS install with nix-darwin:
#   1. Installs Nix via the Determinate Systems installer if absent
#   2. Re-execs under `nix shell` to get a pinned tool environment
#   3. Configures GPG smartcard coexistence
#   4. Clones nixos-config + nix-secrets via YubiKey SSH auth
#   5. Decrypts the YubiKey-encrypted age identity blob
#      → ~/Library/Application Support/sops/age/keys.txt
#      (matches vars.age.keyFile for isDarwin in flake/lib/mk-vars.nix)
#   6. Optionally activates the nix-darwin configuration
#
# Run as your normal user. sudo is used only where unavoidable.
# YubiKey must be plugged in; you will be prompted to touch it once.
#
# For testing without the nix shell re-exec, set:
#   _DARWIN_BOOTSTRAP_NIX_SHELL=1 bash bootstrap/install-darwin.sh ...
set -euo pipefail

# ---------------------------------------------------------------------------
# Phase 1: pre-Nix setup and re-exec guard
# ---------------------------------------------------------------------------
if [[ "${_DARWIN_BOOTSTRAP_NIX_SHELL:-0}" != "1" ]]; then

  # Minimum macOS version: nix-darwin requires Sonoma (14.0)+
  _macos_ver="$(sw_vers -productVersion)"
  _macos_major="${_macos_ver%%.*}"
  if [[ "$_macos_major" -lt 14 ]]; then
    echo "ERROR: macOS 14 (Sonoma) or later required. Found: $_macos_ver" >&2
    exit 1
  fi

  # Install Nix if absent
  if ! command -v nix >/dev/null 2>&1; then
    echo "Nix not found — installing via Determinate Systems installer..."
    # Idempotent, multi-user, works on Apple Silicon and Intel.
    curl --proto '=https' --tlsv1.2 -sSf \
      https://install.determinate.systems/nix | sh -s -- install --no-confirm
    # Source the daemon profile so `nix` is on PATH immediately
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh || true
    echo "Nix installed: $(nix --version)"
  else
    echo "Nix found: $(nix --version)"
  fi

  echo "Re-executing under nix shell for pinned tool environment..."
  exec env _DARWIN_BOOTSTRAP_NIX_SHELL=1 \
    nix shell \
      nixpkgs#bashInteractive \
      nixpkgs#coreutils \
      nixpkgs#git \
      nixpkgs#openssh \
      nixpkgs#gnupg \
      nixpkgs#age \
      nixpkgs#age-plugin-yubikey \
      --command bash -- "$0" "$@"
fi

# ---------------------------------------------------------------------------
# Phase 2: running inside the nix shell tool environment
# ---------------------------------------------------------------------------
export PLATFORM="darwin"
SCRIPT_NAME="install-darwin.sh"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
  usage_common
  cat <<EOF

Darwin notes:
  TARGET is always / on macOS — there is no install-time mountpoint.

  Age key path is fixed to match flake/lib/mk-vars.nix (isDarwin branch):
    ~/Library/Application Support/sops/age/keys.txt

Examples:
  # Dry-run
  bootstrap/install-darwin.sh --host macbook

  # Full activation
  bootstrap/install-darwin.sh --host macbook --install

Notes:
  - Run as your normal user, not root.
  - YubiKey must be plugged in; you will be prompted to touch it.
  - On a fresh Mac, Nix is installed automatically before proceeding.
  - nix-darwin does not need to be pre-installed; the script handles
    first-time activation via `nix run`.
EOF
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
arg_defaults   # HOST=macbook, TARGET=/ for darwin

REMAINING_ARGS=()
parse_common_args "$@"

[[ ${#REMAINING_ARGS[@]} -eq 0 ]] \
  || die "Unknown argument(s): ${REMAINING_ARGS[*]}"

# Darwin paths — TARGET is always /, no mount prefix
[[ -n "$CONFIG_DEST" ]] || CONFIG_DEST="$HOME/nixos-config"

# Age key path MUST match mk-vars.nix isDarwin branch:
#   "${homePrefix}/${username}/Library/Application Support/sops/age/keys.txt"
# This is user-owned; no sudo required.
AGE_KEYS_DIR="$HOME/Library/Application Support/sops/age"
AGE_KEYS_FILE="$AGE_KEYS_DIR/keys.txt"

SECRETS_DEST="$(dirname "$CONFIG_DEST")/$SECRETS_SUBDIR"
SECRETS_BLOB="$SECRETS_DEST/$SECRETS_BLOB_REL"

MODE="dry-run"; [[ $DO_INSTALL -eq 1 ]] && MODE="install"

resolve_sudo

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo "=== nix-darwin bootstrap (YubiKey-first) ==="
echo "Repo root    : $ROOT_DIR"
echo "User         : $USER_NAME"
echo "Host         : $HOST"
echo "Mode         : $MODE"
echo "Config dest  : $CONFIG_DEST"
echo "Secrets dest : $SECRETS_DEST"
echo "Secrets blob : $SECRETS_BLOB_REL"
echo "Age key file : $AGE_KEYS_FILE"
echo

# Advisory check for /run symlink (nix-darwin creates this on first activation)
if [[ ! -L /run ]] && [[ ! -d /run ]]; then
  echo "Note: /run does not exist yet — nix-darwin will create it on first activation."
  echo "      A reboot or new shell session may be needed afterwards."
  echo
fi

# ---------------------------------------------------------------------------
# Bootstrap steps
# ---------------------------------------------------------------------------
mkdir -p "$(dirname "$CONFIG_DEST")"

setup_gpg_smartcard
setup_known_hosts
check_yubikey_age

clone_or_update_repo "nixos-config" "$NIXOS_CONFIG_ORIGIN" "$CONFIG_DEST"
clone_or_update_repo "nix-secrets"  "$NIX_SECRETS_ORIGIN"  "$SECRETS_DEST" "$NIX_SECRETS_BRANCH"

# root_owned=false: Darwin age key is user-owned under ~/Library
decrypt_age_blob "$SECRETS_BLOB" "$AGE_KEYS_DIR" "$AGE_KEYS_FILE" "false"

# ---------------------------------------------------------------------------
# Result
# ---------------------------------------------------------------------------
echo
echo "✅ Bootstrap complete."
echo
echo "  $CONFIG_DEST   → nixos-config"
echo "  $SECRETS_DEST  → nix-secrets"
echo "  $AGE_KEYS_FILE → sops-nix age keyFile"
echo

if [[ $DO_INSTALL -eq 0 ]]; then
  echo "Dry-run — next steps:"
  echo "  If nix-darwin has been activated before on this machine:"
  echo "    darwin-rebuild switch --flake $CONFIG_DEST#$HOST"
  echo
  echo "  First-time activation:"
  echo "    nix run nix-darwin#darwin-rebuild -- switch --flake $CONFIG_DEST#$HOST"
  echo
  echo "  After first activation, open a new shell for PATH changes to take effect."
  exit 0
fi

# ---------------------------------------------------------------------------
# Install mode — activate nix-darwin configuration
# ---------------------------------------------------------------------------
echo "=== Activating nix-darwin ==="
[[ -f "$AGE_KEYS_FILE"    ]] || die "Age key missing: $AGE_KEYS_FILE"
[[ -d "$CONFIG_DEST/.git" ]] || die "nixos-config clone missing: $CONFIG_DEST"

if darwin-rebuild --version >/dev/null 2>&1; then
  echo "Running darwin-rebuild switch..."
  darwin-rebuild switch --flake "$CONFIG_DEST#$HOST"
else
  echo "darwin-rebuild not in PATH — running first-time activation via nix run..."
  # Current nix-darwin bootstrap command (LnL7/nix-darwin, post-flakes):
  # https://github.com/LnL7/nix-darwin#flakes
  nix run nix-darwin#darwin-rebuild -- switch --flake "$CONFIG_DEST#$HOST"
fi

echo
echo "✅ nix-darwin activation completed."
echo
echo "Open a new terminal for PATH and shell integrations to take effect."
