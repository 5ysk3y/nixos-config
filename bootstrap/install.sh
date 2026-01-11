#!/usr/bin/env -S nix shell nixpkgs#bashInteractive nixpkgs#coreutils nixpkgs#git nixpkgs#openssh nixpkgs#gnupg nixpkgs#pcsclite nixpkgs#age nixpkgs#age-plugin-yubikey --command bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

die() { echo "ERROR: $*" >&2; exit 1; }

usage() {
  cat <<EOF
Usage: bootstrap/install.sh [--target /mnt] [--user username] [--uid 1000] [--gid 100] [--host hostname] [--dry-run|--install] [--config-dest PATH] [--secrets-subdir PATH] [--secrets-blob PATH]

This script bootstraps a fresh NixOS install using a single YubiKey:

  - Ensures pcscd + gpg smartcard coexist cleanly (scdaemon disable-ccid)
  - Uses YubiKey-backed SSH auth to clone:
      - nixos-config into <config-dest>
      - nix-secrets into <config-dest>/<secrets-subdir>
  - Decrypts YubiKey-encrypted age identity blob from nix-secrets:
      - writes <target>/var/lib/age/keys.txt
  - (--install) runs nixos-install using the cloned nixos-config flake

Options:
  --target PATH         Target mountpoint (default: /mnt)
  --user NAME           Username for target home path (default: rickie)
  --uid N               UID for ownership of <target>/home/<user> (default: 1000)
  --gid N               GID for ownership of <target>/home/<user> (default: 100)
  --host NAME           Hostname to install (default: gibson)
  --dry-run             Do not run nixos-install (default)
  --install             Run nixos-install after bootstrapping secrets
  --config-dest PATH    Where to place nixos-config in the target
                        (default: <target>/home/<user>/nixos-config)
  --secrets-subdir PATH Where nix-secrets is cloned relative to config-dest
                        (default: secrets)
  --secrets-blob PATH   Path to the encrypted age identity blob inside nix-secrets
                        (default: bootstrap/age-keys.txt.age)
  --help                Show this help

Notes:
  - Run this as your normal user, not with sudo.
    The script will sudo only for the few target root paths it must write.
  - Requires the YubiKey to be plugged in, you will be prompted to touch it.
  - Uses your existing SSH, YubiKey setup to access GitHub (git@github.com).
EOF
}

TARGET="/mnt"
HOST="gibson"
USER_NAME="rickie"
USER_UID="1000"
USER_GID="100"
DO_INSTALL=0
CONFIG_DEST=""
SECRETS_SUBDIR="secrets"
SECRETS_BLOB_REL="bootstrap/age-keys.txt.age"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2;;
    --host) HOST="$2"; shift 2;;
    --user) USER_NAME="$2"; shift 2;;
    --uid) USER_UID="$2"; shift 2;;
    --gid) USER_GID="$2"; shift 2;;
    --install) DO_INSTALL=1; shift;;
    --dry-run) DO_INSTALL=0; shift;;
    --config-dest) CONFIG_DEST="$2"; shift 2;;
    --secrets-subdir) SECRETS_SUBDIR="$2"; shift 2;;
    --secrets-blob) SECRETS_BLOB_REL="$2"; shift 2;;
    --help|-h) usage; exit 0;;
    *) die "Unknown arg: $1";;
  esac
done

[[ -n "$CONFIG_DEST" ]] || CONFIG_DEST="$TARGET/home/$USER_NAME/nixos-config"

MODE="dry-run"
[[ $DO_INSTALL -eq 1 ]] && MODE="install"

NIXOS_CONFIG_ORIGIN="git@github.com:5ysk3y/nixos-config.git"
NIX_SECRETS_ORIGIN="git@github.com:5ysk3y/nix-secrets.git"
NIX_SECRETS_BRANCH="main"

# --- Paths in the TARGET filesystem ---
USER_HOME="$TARGET/home/$USER_NAME"
AGE_KEYS_DIR="$TARGET/var/lib/age"
AGE_KEYS_FILE="$AGE_KEYS_DIR/keys.txt"

CONFIG_PARENT="$(dirname "$CONFIG_DEST")"
SECRETS_DEST="$CONFIG_DEST/$SECRETS_SUBDIR"
SECRETS_BLOB="$SECRETS_DEST/$SECRETS_BLOB_REL"

TMPDIR="$(mktemp -d)"
YUBI_IDENT="$TMPDIR/yubikey-identity.txt"
CLEANUP_DONE=0
cleanup() {
  if [[ $CLEANUP_DONE -eq 0 ]]; then
    rm -rf "$TMPDIR"
    CLEANUP_DONE=1
  fi
}
trap cleanup EXIT

# Use sudo only when needed
SUDO=""
if [[ ${EUID:-0} -ne 0 ]]; then
  command -v sudo >/dev/null 2>&1 || die "This script needs sudo available for a few steps when not run as root."
  SUDO="sudo"
fi

echo "=== NixOS bootstrap (YubiKey-first) ==="
echo "Repo root:     $ROOT_DIR"
echo "Target:        $TARGET"
echo "User:          $USER_NAME ($USER_UID:$USER_GID)"
echo "Host:          $HOST"
echo "Mode:          $MODE"
echo "Config dest:   $CONFIG_DEST"
echo "Secrets dest:  $SECRETS_DEST"
echo "Secrets blob:  $SECRETS_BLOB_REL"
echo

[[ -d "$TARGET" ]] || die "Target path does not exist: $TARGET"

echo "Preparing target directories..."
# These may fail if TARGET is root-owned, that’s fine, we fall back to sudo
mkdir -p "$TARGET/etc/nixos" "$USER_HOME" "$CONFIG_PARENT" 2>/dev/null || true
$SUDO mkdir -p "$TARGET/etc/nixos" "$USER_HOME" "$CONFIG_PARENT"
$SUDO mkdir -p "$TARGET/var/lib" "$AGE_KEYS_DIR"

$SUDO chown -R "$USER_UID:$USER_GID" "$USER_HOME" >/dev/null 2>&1 || true

# --- Ensure smartcard plumbing works cleanly (pcscd + GPG coexistence) ---
# We configure scdaemon disable-ccid for the CURRENT user running the script.
GNUPG_HOME="${GNUPGHOME:-$HOME/.gnupg}"
mkdir -p "$GNUPG_HOME"
chmod 700 "$GNUPG_HOME"

SCDAEMON_CONF="$GNUPG_HOME/scdaemon.conf"
if ! grep -qx 'disable-ccid' "$SCDAEMON_CONF" 2>/dev/null; then
  echo "Configuring GnuPG scdaemon to avoid CCID conflicts (disable-ccid)..."
  echo "disable-ccid" >> "$SCDAEMON_CONF"
fi

echo "Restarting smartcard daemons..."
gpgconf --kill scdaemon >/dev/null 2>&1 || true
gpgconf --kill gpg-agent >/dev/null 2>&1 || true

if command -v systemctl >/dev/null 2>&1; then
  $SUDO systemctl restart pcscd >/dev/null 2>&1 || true
else
  $SUDO pkill pcscd >/dev/null 2>&1 || true
  $SUDO pcscd >/dev/null 2>&1 || true
fi

# --- Ensure SSH can talk to GitHub (known_hosts) ---
SSH_DIR="${HOME}/.ssh"
KNOWN_HOSTS="${SSH_DIR}/known_hosts"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
touch "$KNOWN_HOSTS"
chmod 600 "$KNOWN_HOSTS"

if ! ssh-keygen -F github.com -f "$KNOWN_HOSTS" >/dev/null 2>&1; then
  echo "Adding github.com to known_hosts..."
  ssh-keyscan -t rsa,ecdsa,ed25519 github.com >> "$KNOWN_HOSTS" 2>/dev/null || true
fi

# --- Quick probe that the YubiKey age plugin sees a key ---
echo "Checking YubiKey age identities..."
AGE_RECIP="$(age-plugin-yubikey --list | grep . | tail -n1 || true)"
[[ -n "$AGE_RECIP" ]] || die "No YubiKey age recipients found. Expected 'age-plugin-yubikey --list' to show at least one. Is the YubiKey inserted and usable?"

echo "Using YubiKey recipient: $AGE_RECIP"
echo

# --- Clone nixos-config into target, IMPORTANT: runs as invoking user so SSH agent works ---
if [[ -d "$CONFIG_DEST/.git" ]]; then
  echo "nixos-config already exists at $CONFIG_DEST, fetching latest..."
  git -C "$CONFIG_DEST" fetch --all --prune
else
  echo "Cloning nixos-config into $CONFIG_DEST..."
  $SUDO rm -rf "$CONFIG_DEST" >/dev/null 2>&1 || true
  rm -rf "$CONFIG_DEST"
  git clone "$NIXOS_CONFIG_ORIGIN" "$CONFIG_DEST"
fi

# --- Clone nix-secrets under nixos-config tree ---
if [[ -d "$SECRETS_DEST/.git" ]]; then
  echo "nix-secrets already exists at $SECRETS_DEST, fetching latest..."
  git -C "$SECRETS_DEST" fetch --all --prune
  git -C "$SECRETS_DEST" checkout "$NIX_SECRETS_BRANCH"
  git -C "$SECRETS_DEST" reset --hard "origin/$NIX_SECRETS_BRANCH"
else
  echo "Cloning nix-secrets into $SECRETS_DEST..."
  mkdir -p "$(dirname "$SECRETS_DEST")"
  rm -rf "$SECRETS_DEST"
  git clone --branch "$NIX_SECRETS_BRANCH" "$NIX_SECRETS_ORIGIN" "$SECRETS_DEST"
fi

# Ownership of the config tree should belong to the target user
$SUDO chown -R "$USER_UID:$USER_GID" "$CONFIG_DEST" >/dev/null 2>&1 || true

# --- Decrypt the YubiKey-encrypted age identity blob into the target root ---
[[ -f "$SECRETS_BLOB" ]] || die "Missing secrets blob: $SECRETS_BLOB"

echo
echo "Generating YubiKey identity descriptor (non-secret)..."
age-plugin-yubikey --identity > "$YUBI_IDENT"

echo "Decrypting age identity blob, requires YubiKey touch..."
$SUDO install -d -m 0700 "$AGE_KEYS_DIR"
$SUDO age -d -i "$YUBI_IDENT" -o "$AGE_KEYS_FILE" "$SECRETS_BLOB"
$SUDO chmod 0600 "$AGE_KEYS_FILE"
$SUDO chown root:root "$AGE_KEYS_FILE"

echo
echo "✅ Bootstrap complete."
echo
echo "What exists in target now:"
echo "  - $CONFIG_DEST                     -> nixos-config (git clone)"
echo "  - $SECRETS_DEST                    -> nix-secrets  (git clone)"
echo "  - $AGE_KEYS_FILE                   -> sops-nix age keyFile on installed system"
echo

if [[ $DO_INSTALL -eq 0 ]]; then
  echo "Next steps:"
  echo "  1) Review config at: $CONFIG_DEST"
  echo "  2) Run: nixos-install --root $TARGET --flake $CONFIG_DEST#$HOST"
  exit 0
fi

echo "=== Install mode ==="

[[ -d "$TARGET/etc" ]] || die "Target looks wrong: $TARGET/etc missing"
[[ -f "$AGE_KEYS_FILE" ]] || die "Age key missing at $AGE_KEYS_FILE"
[[ -d "$CONFIG_DEST/.git" ]] || die "nixos-config clone missing at $CONFIG_DEST"

echo "Running nixos-install..."
# Keep essentials (especially SSH_AUTH_SOCK) so git+ssh flake inputs can work during install if needed.
$SUDO env -i \
  HOME="$HOME" \
  USER="$USER" \
  PATH="$PATH" \
  SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-}" \
  NIX_CONFIG="${NIX_CONFIG:-}" \
  nixos-install --root "$TARGET" --flake "$CONFIG_DEST#$HOST"

echo "✅ nixos-install completed."
