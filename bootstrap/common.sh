#!/usr/bin/env bash
# bootstrap/common.sh
# Sourced by install.sh and install-darwin.sh — never executed directly.
#
# Provides:
#   die, usage_common, arg_defaults, parse_common_args,
#   resolve_sudo, setup_gpg_smartcard, setup_known_hosts,
#   check_yubikey_age, clone_or_update_repo, decrypt_age_blob
#
# Callers MUST export before sourcing:
#   PLATFORM      "linux" | "darwin"
#   SCRIPT_NAME   basename of the calling script (for usage strings)
#
# Callers inherit:
#   YUBI_IDENT    path to temp file for the YubiKey identity descriptor
#                 (written by decrypt_age_blob, cleaned up on EXIT)

# ---------------------------------------------------------------------------
# Guard: must be sourced, not executed
# ---------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "ERROR: common.sh must be sourced, not executed directly." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Verify required caller-set variables
# ---------------------------------------------------------------------------
die() { echo "ERROR: $*" >&2; exit 1; }

[[ -n "${PLATFORM:-}"     ]] || die "PLATFORM must be exported before sourcing common.sh"
[[ -n "${SCRIPT_NAME:-}"  ]] || die "SCRIPT_NAME must be set before sourcing common.sh"
[[ "$PLATFORM" == "linux" || "$PLATFORM" == "darwin" ]] \
  || die "PLATFORM must be 'linux' or 'darwin', got: $PLATFORM"

# ---------------------------------------------------------------------------
# Defaults — called by each install script before arg parsing
# ---------------------------------------------------------------------------
arg_defaults() {
  NIXOS_CONFIG_ORIGIN="git@github.com:5ysk3y/nixos-config.git"
  NIX_SECRETS_ORIGIN="git@github.com:5ysk3y/nix-secrets.git"
  NIX_SECRETS_BRANCH="main"

  # GPG public key URL — used to import the key on a fresh system so the
  # YubiKey can be associated and SSH auth via gpg-agent can work.
  GPG_KEY_URL="https://github.com/5ysk3y.gpg"

  USER_NAME="rickie"
  USER_UID="1000"
  USER_GID="100"
  DO_INSTALL=0
  CONFIG_DEST=""
  SECRETS_SUBDIR="secrets"
  SECRETS_BLOB_REL="bootstrap/age-keys.txt.age"

  if [[ "$PLATFORM" == "darwin" ]]; then
    HOST="macbook"
    TARGET="/"
  else
    HOST="gibson"
    TARGET="/mnt"
  fi
}

# ---------------------------------------------------------------------------
# Usage preamble — callers append platform-specific sections
# ---------------------------------------------------------------------------
usage_common() {
  cat <<EOF
Usage: bootstrap/${SCRIPT_NAME} [OPTIONS]

Shared options:
  --user NAME           Username (default: rickie)
  --uid N               UID      (default: 1000)
  --gid N               GID      (default: 100)
  --host NAME           Flake host attribute to build
  --dry-run             Clone + decrypt secrets, then stop (default)
  --install             Also run the final install step
  --config-dest PATH    Where to clone nixos-config
  --secrets-subdir DIR  nix-secrets dir relative to config-dest (default: secrets)
  --secrets-blob PATH   Encrypted age identity blob inside nix-secrets
                        (default: bootstrap/age-keys.txt.age)
  --help | -h           Show this help
EOF
}

# ---------------------------------------------------------------------------
# Argument parser
# Unknown flags accumulate in REMAINING_ARGS for the caller to handle or reject.
# ---------------------------------------------------------------------------
parse_common_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --user)           USER_NAME="$2";        shift 2 ;;
      --uid)            USER_UID="$2";         shift 2 ;;
      --gid)            USER_GID="$2";         shift 2 ;;
      --host)           HOST="$2";             shift 2 ;;
      --install)        DO_INSTALL=1;          shift   ;;
      --dry-run)        DO_INSTALL=0;          shift   ;;
      --config-dest)    CONFIG_DEST="$2";      shift 2 ;;
      --secrets-subdir) SECRETS_SUBDIR="$2";   shift 2 ;;
      --secrets-blob)   SECRETS_BLOB_REL="$2"; shift 2 ;;
      --help|-h)        usage; exit 0 ;;
      *)                REMAINING_ARGS+=("$1"); shift ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# Sudo helper — resolved once, used everywhere
# ---------------------------------------------------------------------------
resolve_sudo() {
  SUDO=""
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    command -v sudo >/dev/null 2>&1 \
      || die "sudo is required when not running as root."
    SUDO="sudo"
  fi
}

# ---------------------------------------------------------------------------
# GPG / smartcard setup
#
# Handles the full chain required on a fresh system:
#
#   1. scdaemon disable-ccid — prevents the CCID driver competing with pcscd
#      for exclusive USB access to the YubiKey. Without this one daemon wins
#      the device and the other fails silently.
#
#   2. gpg-agent SSH support — enables the agent to serve SSH keys from the
#      YubiKey's OpenPGP auth slot and exports SSH_AUTH_SOCK so git can use it.
#
#   3. GPG public key import — fetches the public key from GitHub so gpg
#      knows about the key and can associate it with the physical card.
#      Required on a fresh system (e.g. NixOS live ISO) where the keyring is
#      empty. Skipped if the key is already present.
#
#   4. pcscd restart — ensures the smartcard daemon is running and has a clean
#      connection to the card. Linux only; macOS PCSC is launchd-managed.
#
#   5. gpg --card-status — wakes the YubiKey and forces gpg to associate the
#      card with the imported public key. Required before SSH auth will work.
#
# On Darwin: pcscd is skipped; everything else applies.
# ---------------------------------------------------------------------------
setup_gpg_smartcard() {
  local gnupg_home="${GNUPGHOME:-$HOME/.gnupg}"
  mkdir -p "$gnupg_home"
  chmod 700 "$gnupg_home"

  # 1. scdaemon: disable-ccid
  local scdaemon_conf="$gnupg_home/scdaemon.conf"
  if ! grep -qx 'disable-ccid' "$scdaemon_conf" 2>/dev/null; then
    echo "Configuring scdaemon: disable-ccid (prevents CCID/PCSC conflict)..."
    echo "disable-ccid" >> "$scdaemon_conf"
  fi

  # 2. gpg-agent: enable SSH support
  local agent_conf="$gnupg_home/gpg-agent.conf"
  if ! grep -qx 'enable-ssh-support' "$agent_conf" 2>/dev/null; then
    echo "Enabling gpg-agent SSH support..."
    echo "enable-ssh-support" >> "$agent_conf"
  fi

  # Restart agent so config changes take effect
  echo "Restarting gpg-agent / scdaemon..."
  gpgconf --kill scdaemon  >/dev/null 2>&1 || true
  gpgconf --kill gpg-agent >/dev/null 2>&1 || true

  # 3. pcscd (Linux only)
  if [[ "$PLATFORM" == "linux" ]]; then
    if command -v systemctl >/dev/null 2>&1 && systemctl is-system-running --quiet 2>/dev/null; then
      $SUDO systemctl restart pcscd >/dev/null 2>&1 || true
    else
      # Non-systemd or systemd not yet running (e.g. NixOS live ISO)
      $SUDO pkill -x pcscd >/dev/null 2>&1 || true
      sleep 1
      $SUDO pcscd --foreground &>/dev/null &
      sleep 1
    fi
  fi
  # Darwin: com.apple.ifdreader is launchd-managed; killing scdaemon is sufficient.

  # 4. Export SSH_AUTH_SOCK so git can use the YubiKey for SSH auth.
  #    gpgconf --list-dirs agent-ssh-socket gives the correct path regardless
  #    of whether the agent was just started or was already running.
  local ssh_sock
  ssh_sock="$(gpgconf --list-dirs agent-ssh-socket 2>/dev/null || true)"
  if [[ -n "$ssh_sock" ]]; then
    export SSH_AUTH_SOCK="$ssh_sock"
  fi

  # 5. Import GPG public key if not already in keyring.
  #    gpg --list-keys exits non-zero if the key is absent.
  echo "Checking GPG keyring..."
  if ! gpg --list-keys "$GPG_KEY_URL" >/dev/null 2>&1; then
    echo "Importing GPG public key from ${GPG_KEY_URL}..."
    gpg --fetch-keys "$GPG_KEY_URL" \
      || die "Failed to fetch GPG public key from ${GPG_KEY_URL} — is the network up?"
  fi

  # 6. Wake the YubiKey and associate the card with the imported key.
  echo "Waking YubiKey smartcard..."
  gpg --card-status >/dev/null 2>&1 \
    || die "YubiKey not detected — is it plugged in? (gpg --card-status)"
}

# ---------------------------------------------------------------------------
# SSH known_hosts — ensure github.com is present before any git operations
# ---------------------------------------------------------------------------
setup_known_hosts() {
  local ssh_dir="${HOME}/.ssh"
  local known_hosts="${ssh_dir}/known_hosts"

  mkdir -p "$ssh_dir"
  chmod 700 "$ssh_dir"
  touch "$known_hosts"
  chmod 600 "$known_hosts"

  if ! ssh-keygen -F github.com -f "$known_hosts" >/dev/null 2>&1; then
    echo "Adding github.com to known_hosts..."
    ssh-keyscan -t rsa,ecdsa,ed25519 github.com >> "$known_hosts" \
      || die "ssh-keyscan github.com failed — is the network up?"
  fi
}

# ---------------------------------------------------------------------------
# YubiKey age identity probe
# Fails fast with a clear message if no YubiKey age slot is visible.
# ---------------------------------------------------------------------------
check_yubikey_age() {
  echo "Checking YubiKey age identities..."
  local recip
  recip="$(age-plugin-yubikey --list 2>/dev/null | grep . | tail -n1 || true)"
  [[ -n "$recip" ]] \
    || die "No YubiKey age recipients found — is the key inserted? (age-plugin-yubikey --list)"
  echo "Found YubiKey recipient: $recip"
}

# ---------------------------------------------------------------------------
# Clone or update a git repository
#
#   clone_or_update_repo LABEL ORIGIN DEST [BRANCH]
#
# Without BRANCH (nixos-config): fetch + fast-forward only. Local commits are
# preserved; divergence is reported but not fatal.
#
# With BRANCH (nix-secrets): fetch + hard-reset to origin/BRANCH. This repo
# is treated as read-only canonical state — no local modifications expected.
# ---------------------------------------------------------------------------
clone_or_update_repo() {
  local label="$1" origin="$2" dest="$3" branch="${4:-}"

  if [[ -d "$dest/.git" ]]; then
    echo "${label}: already cloned at ${dest}, updating..."
    git -C "$dest" fetch --all --prune

    if [[ -n "$branch" ]]; then
      git -C "$dest" checkout "$branch"
      git -C "$dest" reset --hard "origin/$branch"
    else
      local current_branch
      current_branch="$(git -C "$dest" branch --show-current 2>/dev/null || true)"
      if [[ -n "$current_branch" ]]; then
        git -C "$dest" merge --ff-only "origin/$current_branch" 2>/dev/null \
          || echo "  (fast-forward skipped — local commits present or branch diverged)"
      fi
    fi
  else
    echo "${label}: cloning into ${dest}..."
    mkdir -p "$(dirname "$dest")"
    rm -rf "$dest"
    if [[ -n "$branch" ]]; then
      git clone --branch "$branch" "$origin" "$dest"
    else
      git clone "$origin" "$dest"
    fi
  fi
}

# ---------------------------------------------------------------------------
# Decrypt the YubiKey-encrypted age identity blob
#
#   decrypt_age_blob BLOB_PATH KEYS_DIR KEYS_FILE IS_ROOT_OWNED
#
# IS_ROOT_OWNED: "true"  = chown root:root + sudo (Linux /var/lib/age)
#                "false" = user-owned, no sudo  (Darwin ~/Library/...)
# ---------------------------------------------------------------------------
decrypt_age_blob() {
  local blob="$1" keys_dir="$2" keys_file="$3" root_owned="${4:-false}"

  [[ -f "$blob" ]] || die "Missing secrets blob: ${blob}"

  echo "Generating YubiKey identity descriptor..."
  age-plugin-yubikey --identity > "$YUBI_IDENT"

  echo "Decrypting age identity blob — touch your YubiKey when prompted..."

  if [[ "$root_owned" == "true" ]]; then
    $SUDO install -d -m 0700 "$keys_dir"
    $SUDO age -d -i "$YUBI_IDENT" -o "$keys_file" "$blob"
    $SUDO chmod 0600 "$keys_file"
    $SUDO chown root:root "$keys_file"
  else
    mkdir -p "$keys_dir"
    chmod 0700 "$keys_dir"
    age -d -i "$YUBI_IDENT" -o "$keys_file" "$blob"
    chmod 0600 "$keys_file"
  fi
}

# ---------------------------------------------------------------------------
# Shared temp directory — provides $YUBI_IDENT to decrypt_age_blob
# Cleaned up on EXIT of the sourcing script.
# ---------------------------------------------------------------------------
_BS_TMPDIR="$(mktemp -d)"
YUBI_IDENT="$_BS_TMPDIR/yubikey-identity.txt"

_bs_cleanup() { rm -rf "$_BS_TMPDIR"; }
trap _bs_cleanup EXIT
