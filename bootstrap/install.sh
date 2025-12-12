#!/usr/bin/env -S nix shell nixpkgs#bashInteractive nixpkgs#age nixpkgs#git nixpkgs#openssh nixpkgs#coreutils --command bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

AGE_KEY_TMP="$(mktemp)"
GH_KEY_TMP="$(mktemp)"
CLEANUP_DONE=0

cleanup() {
  if [[ $CLEANUP_DONE -eq 0 ]]; then
    rm -f "$AGE_KEY_TMP" "$GH_KEY_TMP"
    CLEANUP_DONE=1
  fi
}
trap cleanup EXIT

die() { echo "ERROR: $*" >&2; exit 1; }

usage() {
  cat <<EOF
Usage: bootstrap/install.sh [--target /mnt] [--user username] [--uid 1000] [--gid 100] [--host hostname] [--dry-run|--install] [--config-dest PATH]

This script bootstraps secrets into a target mount (typically /mnt) so NixOS can be installed from scratch:

  - Decrypts bootstrap age identity and GitHub deploy SSH key
  - Creates a bare transport repo at <target>/home/<user>/.cache/nix-secrets.git
  - Deploys full secrets work-tree to <target>/etc/nixos/nix-secrets (no .git)
  - Writes age keys to <target>/var/lib/age/keys.txt
  - (--install) copies nixos-config into the target and runs nixos-install

Options:
  --target PATH       Target mountpoint (default: /mnt)
  --user NAME         Username for cache path (default: rickie)
  --uid N             UID for ownership of cache dir (default: 1000)
  --gid N             GID for ownership of cache dir (default: 100)
  --host NAME         Hostname to install (default: gibson)
  --dry-run           Do not run nixos-install (default)
  --install           Run nixos-install after bootstrapping secrets
  --config-dest PATH  Where to place nixos-config in the target (default: <target>/home/<user>/nixos-config)
  --help              Show this help
EOF
}

TARGET="/mnt"
HOST="gibson"
USER_NAME="rickie"
USER_UID="1000"
USER_GID="100"
DO_INSTALL=0
CONFIG_DEST=""

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
    --help|-h) usage; exit 0;;
    *) die "Unknown arg: $1";;
  esac
done

[[ -n "$CONFIG_DEST" ]] || CONFIG_DEST="$TARGET/home/$USER_NAME/nixos-config"

MODE="dry-run"
[[ $DO_INSTALL -eq 1 ]] && MODE="install"

echo "=== NixOS bootstrap (secrets deploy) ==="
echo "Repo root: $ROOT_DIR"
echo "Target:    $TARGET"
echo "User:      $USER_NAME ($USER_UID:$USER_GID)"
echo "Host:      $HOST"
echo "Mode:      $MODE"
echo

[[ -d "$TARGET" ]] || die "Target path does not exist: $TARGET"
[[ -f "$ROOT_DIR/secrets/bootstrap-age-master.enc" ]] || die "Missing $ROOT_DIR/secrets/bootstrap-age-master.enc"
[[ -f "$ROOT_DIR/secrets/bootstrap-gh-token.enc" ]] || die "Missing $ROOT_DIR/secrets/bootstrap-gh-token.enc"

# --- Paths in the TARGET filesystem ---
USER_HOME="$TARGET/home/$USER_NAME"
CACHE_DIR="$USER_HOME/.cache"
SECRETS_BARE="$CACHE_DIR/nix-secrets.git"
SECRETS_WORKTREE="$TARGET/etc/nixos/nix-secrets"

AGE_KEYS_DIR="$TARGET/var/lib/age"
AGE_KEYS_FILE="$AGE_KEYS_DIR/keys.txt"

ORIGIN="git@github.com:5ysk3y/nix-secrets.git"
BRANCH="main"

# Force SSH to use ONLY the deploy key; do not talk to agent/YubiKey
SSH_OPTS=(
  -i "$GH_KEY_TMP"
  -o IdentitiesOnly=yes
  -o IdentityAgent=none
  -o StrictHostKeyChecking=accept-new
)

echo "Decrypting age master key..."
age --decrypt "$ROOT_DIR/secrets/bootstrap-age-master.enc" > "$AGE_KEY_TMP"
[[ -s "$AGE_KEY_TMP" ]] || die "Failed to decrypt age master key (empty output)"
chmod 600 "$AGE_KEY_TMP"
echo "Age master key decrypted to $AGE_KEY_TMP"
echo

echo "Decrypting GitHub deploy SSH key..."
age --decrypt -i "$AGE_KEY_TMP" "$ROOT_DIR/secrets/bootstrap-gh-token.enc" > "$GH_KEY_TMP"
[[ -s "$GH_KEY_TMP" ]] || die "Failed to decrypt GitHub deploy key (empty output)"
chmod 600 "$GH_KEY_TMP"
echo "GitHub deploy key decrypted to $GH_KEY_TMP"
echo

echo "Preparing target directories..."
mkdir -p "$TARGET/etc/nixos" "$TARGET/var/lib" "$CACHE_DIR" "$AGE_KEYS_DIR"
chown -R "$USER_UID:$USER_GID" "$USER_HOME" || true

echo "  bare repo:  $SECRETS_BARE"
echo "  work-tree:  $SECRETS_WORKTREE"
echo "  age keys:   $AGE_KEYS_FILE"
echo

# Clone bare repo into the user's cache within the target
if [[ ! -d "$SECRETS_BARE" ]]; then
  echo "Cloning nix-secrets (bare) into $SECRETS_BARE..."
  SSH_AUTH_SOCK= \
    GIT_SSH_COMMAND="ssh ${SSH_OPTS[*]}" \
    git clone --bare "$ORIGIN" "$SECRETS_BARE"
    
fi

# Ensure refs/remotes/origin/main exists in the bare repo (explicit refspec!)
echo "Fetching origin/$BRANCH into refs/remotes/origin/$BRANCH..."
SSH_AUTH_SOCK= \
  GIT_SSH_COMMAND="ssh ${SSH_OPTS[*]}" \
   git --git-dir="$SECRETS_BARE" fetch origin "$BRANCH:refs/remotes/origin/$BRANCH"

# Ensure bare repo is fully user-owned (prevents later permission issues)
chown -R "$USER_UID:$USER_GID" "$SECRETS_BARE"

# Deploy work-tree with NO .git
echo "Deploying secrets work-tree to $SECRETS_WORKTREE..."
mkdir -p "$SECRETS_WORKTREE"

git -c safe.directory="$SECRETS_WORKTREE" \
  --git-dir="$SECRETS_BARE" --work-tree="$SECRETS_WORKTREE" \
  checkout -f -B "$BRANCH" "refs/remotes/origin/$BRANCH"

git -c safe.directory="$SECRETS_WORKTREE" \
  --git-dir="$SECRETS_BARE" --work-tree="$SECRETS_WORKTREE" \
  reset --hard "refs/remotes/origin/$BRANCH"

# Ensure user owns bare secrets
chown -R "$USER_UID:$USER_GID" "$SECRETS_BARE"

# Ensure root owns deployed secrets
chown -R root:root "$SECRETS_WORKTREE"
chmod -R go-rwx "$SECRETS_WORKTREE" || true

# Install age key where sops-nix will look on the installed system
echo "Installing age key to $AGE_KEYS_FILE..."
install -m 0600 "$AGE_KEY_TMP" "$AGE_KEYS_FILE"
chown root:root "$AGE_KEYS_FILE"

echo
echo "✅ Secrets bootstrap complete."
echo
echo "What exists in target now:"
echo "  - $SECRETS_WORKTREE (root-owned, no .git)  -> flake input path"
echo "  - $SECRETS_BARE (user-owned bare repo)     -> live updates can fetch as $USER_NAME"
echo "  - $AGE_KEYS_FILE                           -> sops-nix decryption key"
echo

if [[ $DO_INSTALL -eq 0 ]]; then
  echo "Next steps:"
  echo "  1) Clone/copy nixos-config into $CONFIG_DEST (or wherever you prefer)"
  echo "  2) Run nixos-install --root $TARGET --flake $CONFIG_DEST#$HOST"
  exit 0
fi

echo "=== Install mode ==="

# Guardrails: target must look like a mounted NixOS install root
[[ -d "$TARGET/etc" ]] || die "Target looks wrong: $TARGET/etc missing"
[[ -d "$SECRETS_WORKTREE" ]] || die "Secrets work-tree missing at $SECRETS_WORKTREE"
[[ -f "$AGE_KEYS_FILE" ]] || die "Age key missing at $AGE_KEYS_FILE"

echo "Copying nixos-config into target: $CONFIG_DEST"
mkdir -p "$(dirname "$CONFIG_DEST")"
rm -rf "$CONFIG_DEST"
cp -a "$ROOT_DIR" "$CONFIG_DEST"
chown -R "$USER_UID:$USER_GID" "$CONFIG_DEST" || true

echo "Running nixos-install..."
nixos-install --root "$TARGET" --flake "$CONFIG_DEST#$HOST"

echo "✅ nixos-install completed."
