#!/usr/bin/env -S nix shell nixpkgs#bashInteractive nixpkgs#coreutils nixpkgs#git nixpkgs#openssh nixpkgs#gnupg nixpkgs#pcsclite nixpkgs#age nixpkgs#age-plugin-yubikey --command bash
# bootstrap/install.sh — NixOS (Linux) bootstrap
#
# Bootstraps a fresh NixOS install:
#   1. Configures GPG smartcard / pcscd coexistence
#   2. Clones nixos-config + nix-secrets into the target via YubiKey SSH auth
#   3. Decrypts the YubiKey-encrypted age identity blob → /var/lib/age/keys.txt
#   4. Optionally runs nixos-install
#
# Run as your normal user (not root). sudo is used only for target root paths.
# The shebang pulls all required tools from nixpkgs via `nix shell` so the
# script is self-contained on any system with Nix available.
#
# For testing without the nix shell re-exec, set:
#   _NIXOS_BOOTSTRAP_NIX_SHELL=1 bash bootstrap/install.sh ...
set -euo pipefail

# ---------------------------------------------------------------------------
# Phase 1: ensure we are running inside the nix shell tool environment
# The shebang handles this in normal use; the env var bypass is for tests.
# ---------------------------------------------------------------------------
if [[ "${_NIXOS_BOOTSTRAP_NIX_SHELL:-0}" != "1" ]]; then
  # When invoked as `bash install.sh` the shebang is skipped but we still
  # need the tool environment. Re-exec under nix shell.
  exec env _NIXOS_BOOTSTRAP_NIX_SHELL=1 \
    nix shell \
      nixpkgs#bashInteractive \
      nixpkgs#coreutils \
      nixpkgs#git \
      nixpkgs#openssh \
      nixpkgs#gnupg \
      nixpkgs#pcsclite \
      nixpkgs#age \
      nixpkgs#age-plugin-yubikey \
      --command bash -- "$0" "$@"
fi

# ---------------------------------------------------------------------------
# Phase 2: running inside the tool environment
# ---------------------------------------------------------------------------
export PLATFORM="linux"
SCRIPT_NAME="install.sh"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
  usage_common
  cat <<EOF

Linux-specific options:
  --target PATH   Target mountpoint for the new system (default: /mnt)

Examples:
  # Dry-run (clone + decrypt, then show next steps)
  bootstrap/install.sh --host gibson

  # Full install
  bootstrap/install.sh --host gibson --install

  # Custom target
  bootstrap/install.sh --target /mnt --user rickie --host gibson --install

Notes:
  - Run as your normal user, not root.
  - YubiKey must be plugged in; you will be prompted to touch it.
EOF
}

# ---------------------------------------------------------------------------
# Argument parsing — handle --target here, delegate the rest to common
# ---------------------------------------------------------------------------
arg_defaults

REMAINING_ARGS=()
_raw=("$@")
_filtered=()
while [[ ${#_raw[@]} -gt 0 ]]; do
  case "${_raw[0]}" in
    --target) TARGET="${_raw[1]}"; _raw=("${_raw[@]:2}") ;;
    *)        _filtered+=("${_raw[0]}"); _raw=("${_raw[@]:1}") ;;
  esac
done
parse_common_args "${_filtered[@]+"${_filtered[@]}"}"

[[ ${#REMAINING_ARGS[@]} -eq 0 ]] \
  || die "Unknown argument(s): ${REMAINING_ARGS[*]}"

# ---------------------------------------------------------------------------
# Derived paths
# ---------------------------------------------------------------------------
[[ -n "$CONFIG_DEST" ]] || CONFIG_DEST="$TARGET/home/$USER_NAME/nixos-config"

# Verify config dest is inside the target — catches typos before anything destructive
[[ "$CONFIG_DEST" == "$TARGET"* ]] \
  || die "--config-dest ($CONFIG_DEST) is not under --target ($TARGET)"

USER_HOME="$TARGET/home/$USER_NAME"
AGE_KEYS_DIR="$TARGET/var/lib/age"
AGE_KEYS_FILE="$AGE_KEYS_DIR/keys.txt"
CONFIG_PARENT="$(dirname "$CONFIG_DEST")"
SECRETS_DEST="$(dirname "$CONFIG_DEST")/$SECRETS_SUBDIR"
SECRETS_BLOB="$SECRETS_DEST/$SECRETS_BLOB_REL"

MODE="dry-run"; [[ $DO_INSTALL -eq 1 ]] && MODE="install"

resolve_sudo

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo "=== NixOS bootstrap (YubiKey-first) ==="
echo "Repo root    : $ROOT_DIR"
echo "Target       : $TARGET"
echo "User         : $USER_NAME ($USER_UID:$USER_GID)"
echo "Host         : $HOST"
echo "Mode         : $MODE"
echo "Config dest  : $CONFIG_DEST"
echo "Secrets dest : $SECRETS_DEST"
echo "Secrets blob : $SECRETS_BLOB_REL"
echo "Age key file : $AGE_KEYS_FILE"
echo

[[ -d "$TARGET" ]] || die "Target path does not exist: $TARGET"

# ---------------------------------------------------------------------------
# Prepare target directory tree
# ---------------------------------------------------------------------------
echo "Preparing target directories..."
$SUDO mkdir -p "$TARGET/etc/nixos" "$USER_HOME" "$CONFIG_PARENT" \
               "$TARGET/var/lib" "$AGE_KEYS_DIR"
$SUDO chown "$USER_UID:$USER_GID" "$USER_HOME" 2>/dev/null || true

# ---------------------------------------------------------------------------
# Bootstrap steps
# ---------------------------------------------------------------------------
setup_gpg_smartcard
setup_known_hosts
check_yubikey_age

clone_or_update_repo "nixos-config" "$NIXOS_CONFIG_ORIGIN" "$CONFIG_DEST"
clone_or_update_repo "nix-secrets"  "$NIX_SECRETS_ORIGIN"  "$SECRETS_DEST" "$NIX_SECRETS_BRANCH"

$SUDO chown -R "$USER_UID:$USER_GID" "$CONFIG_DEST" "$SECRETS_DEST" 2>/dev/null || true

# root_owned=true: Linux age key lives at /var/lib/age/keys.txt, owned root:root
# sops-nix reads it at activation time with the system identity.
decrypt_age_blob "$SECRETS_BLOB" "$AGE_KEYS_DIR" "$AGE_KEYS_FILE" "true"

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
  echo "  1. Review: $CONFIG_DEST"
  echo "  2. Run:    nixos-install --root $TARGET --flake $CONFIG_DEST#$HOST"
  exit 0
fi

# ---------------------------------------------------------------------------
# Install mode
# ---------------------------------------------------------------------------
echo "=== Running nixos-install ==="
[[ -d "$TARGET/etc"      ]] || die "Target sanity check failed: $TARGET/etc missing"
[[ -f "$AGE_KEYS_FILE"   ]] || die "Age key missing: $AGE_KEYS_FILE"
[[ -d "$CONFIG_DEST/.git" ]] || die "nixos-config clone missing: $CONFIG_DEST"

# Preserve SSH_AUTH_SOCK so flake SSH inputs (nix-secrets) resolve during install.
$SUDO env -i \
  HOME="$HOME" \
  USER="${USER:-$USER_NAME}" \
  PATH="$PATH" \
  SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-}" \
  NIX_CONFIG="${NIX_CONFIG:-}" \
  nixos-install --root "$TARGET" --flake "$CONFIG_DEST#$HOST"

echo "✅ nixos-install completed."
