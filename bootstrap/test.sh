#!/usr/bin/env bash
# bootstrap/test.sh — test harness for the bootstrap scripts
#
# Tests common.sh, install.sh, and install-darwin.sh without a real YubiKey,
# network, or target system. All external commands are stubbed via PATH injection.
#
# install.sh tests bypass nix-shell re-exec via _NIXOS_BOOTSTRAP_NIX_SHELL=1
# install-darwin.sh tests bypass it via _DARWIN_BOOTSTRAP_NIX_SHELL=1
#
# Usage:
#   bash bootstrap/test.sh           # run all tests
#   bash bootstrap/test.sh -v        # verbose
#   bash bootstrap/test.sh -k clone  # filter by name substring
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="$SCRIPT_DIR/common.sh"
INSTALL_LINUX="$SCRIPT_DIR/install.sh"
INSTALL_DARWIN="$SCRIPT_DIR/install-darwin.sh"

# ---------------------------------------------------------------------------
# Framework
# ---------------------------------------------------------------------------
_PASS=0; _FAIL=0; _SKIP=0
VERBOSE=0; FILTER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -v) VERBOSE=1; shift ;;
    -k) FILTER="$2"; shift 2 ;;
    *)  echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

_grp=""
describe() { _grp="$1"; }

it() {
  local desc="$1"; shift
  local name="${_grp}: ${desc}"
  if [[ -n "$FILTER" ]] && [[ "$name" != *"$FILTER"* ]]; then
    (( _SKIP++ )) || true; return
  fi
  [[ $VERBOSE -eq 1 ]] && echo "  .... $name"
  if "$@" >/dev/null 2>&1; then
    (( _PASS++ )) || true; echo "  PASS: $name"
  else
    (( _FAIL++ )) || true; echo "  FAIL: $name"
    "$@" 2>&1 | sed 's/^/      /' || true
  fi
}

summary() {
  echo; echo "Results: ${_PASS} passed, ${_FAIL} failed, ${_SKIP} skipped"
  [[ $_FAIL -eq 0 ]]
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# _setup: initialise T and BIN local variables in the CALLING function.
# Usage at top of each test:  local T BIN; _setup
# The caller is responsible for cleanup: trap "rm -rf '$T'" RETURN
_setup() {
  # Use nameref-style via printf to set caller's locals.
  # We can't use namerefs (bash 4.3+) portably, so instead _setup prints
  # the paths and callers eval them. Simpler: just let each test inline it.
  : # intentionally empty — see pattern in tests below
}

# _stub <BIN> <name> [output]: write a stub that exits 0
_stub() {
  local bin="$1" name="$2" output="${3:-}"
  { printf '#!/usr/bin/env bash\n'; [[ -n "$output" ]] && printf 'echo "%s"\n' "$output"; printf 'exit 0\n'; } \
    > "$bin/$name"
  chmod +x "$bin/$name"
}

# _git_stub <BIN>: git that creates fake .git + bootstrap blob on clone
_git_stub() {
  local bin="$1"
  cat > "$bin/git" << 'GEOF'
#!/usr/bin/env bash
if [[ "$1" == clone ]]; then
  mkdir -p "${@: -1}/.git"
  mkdir -p "${@: -1}/bootstrap"
  touch "${@: -1}/bootstrap/age-keys.txt.age"
fi
exit 0
GEOF
  chmod +x "$bin/git"
}

# _common_stubs <BIN>: all stubs needed to pass setup_* + clone in install scripts
_common_stubs() {
  local bin="$1"
  _stub "$bin" gpgconf
  _stub "$bin" systemctl
  _stub "$bin" ssh-keygen "github.com found"
  _stub "$bin" ssh-keyscan
  _stub "$bin" age-plugin-yubikey "age1yubikey1fakerecipient"
  # gpg stub: list-keys exits 0 (key present), fetch-keys and card-status succeed silently
  cat > "$bin/gpg" << 'GEOF'
#!/usr/bin/env bash
case "$1" in
  --list-keys)  exit 0 ;;
  --fetch-keys) exit 0 ;;
  --card-status) exit 0 ;;
  *) exit 0 ;;
esac
GEOF
  chmod +x "$bin/gpg"
  # sudo stub: silently succeed for chown/install-d (ownership ops that require root)
  # and exec everything else. This prevents both: real sudo prompting on macOS,
  # and chown root:root failing as non-root on macOS.
  cat > "$bin/sudo" << 'SEOF'
#!/usr/bin/env bash
# Skip ownership changes silently — in test environments dirs are already user-owned
case "$1" in
  chown) exit 0 ;;
  install) [[ "$*" == *"-d"* ]] && { shift; exec install "$@"; } || exit 0 ;;
esac
exec "$@"
SEOF
  chmod +x "$bin/sudo"
  # age stub: parse -o <file> and create a fake key file there so chmod/chown succeed
  cat > "$bin/age" << 'AEOF'
#!/usr/bin/env bash
prev=""
for a in "$@"; do
  if [[ "$prev" == "-o" ]]; then
    mkdir -p "$(dirname "$a")"
    echo "AGE-SECRET-KEY-FAKE" > "$a"
  fi
  prev="$a"
done
exit 0
AEOF
  chmod +x "$bin/age"
  _git_stub "$bin"
}

# ---------------------------------------------------------------------------
# ── common.sh sourcing ──────────────────────────────────────────────────────
# ---------------------------------------------------------------------------
describe "common.sh sourcing"

_t_refuses_direct_exec() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  local out; out="$(bash "$COMMON_SH" 2>&1 || true)"
  [[ "$out" == *"must be sourced"* ]]
}
it "refuses direct execution" _t_refuses_direct_exec

_t_fails_no_platform() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  local out; out="$(SCRIPT_NAME=test bash -c "source '$COMMON_SH'" 2>&1 || true)"
  [[ "$out" == *"PLATFORM must be"* ]]
}
it "fails when PLATFORM is unset" _t_fails_no_platform

_t_fails_no_scriptname() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  local out; out="$(bash -c "export PLATFORM=linux; source '$COMMON_SH'" 2>&1 || true)"
  [[ "$out" == *"SCRIPT_NAME must be"* ]]
}
it "fails when SCRIPT_NAME is unset" _t_fails_no_scriptname

_t_fails_bad_platform() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  local out; out="$(PLATFORM=windows SCRIPT_NAME=test bash -c "source '$COMMON_SH'" 2>&1 || true)"
  [[ "$out" == *"PLATFORM must be"* ]]
}
it "fails with invalid PLATFORM value" _t_fails_bad_platform

_t_sources_linux() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  bash -c "export PLATFORM=linux; SCRIPT_NAME=test source '$COMMON_SH'"
}
it "sources cleanly for linux" _t_sources_linux

_t_sources_darwin() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  bash -c "export PLATFORM=darwin; SCRIPT_NAME=test source '$COMMON_SH'"
}
it "sources cleanly for darwin" _t_sources_darwin

# ---------------------------------------------------------------------------
describe "arg_defaults"

_t_defaults_linux() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  bash -c "
    export PLATFORM=linux; SCRIPT_NAME=test source '$COMMON_SH'
    arg_defaults
    [[ \$TARGET == '/mnt' ]] && [[ \$HOST == 'gibson' ]] && [[ \$USER_NAME == 'rickie' ]]
  "
}
it "linux: TARGET=/mnt HOST=gibson USER=rickie" _t_defaults_linux

_t_defaults_darwin() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  bash -c "
    export PLATFORM=darwin; SCRIPT_NAME=test source '$COMMON_SH'
    arg_defaults
    [[ \$TARGET == '/' ]] && [[ \$HOST == 'macbook' ]]
  "
}
it "darwin: TARGET=/ HOST=macbook" _t_defaults_darwin

# ---------------------------------------------------------------------------
describe "parse_common_args"

_t_parse_user() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  bash -c "export PLATFORM=linux; SCRIPT_NAME=test source '$COMMON_SH'; arg_defaults; REMAINING_ARGS=(); parse_common_args --user bob; [[ \$USER_NAME == 'bob' ]]"
}
it "parses --user" _t_parse_user

_t_parse_host() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  bash -c "export PLATFORM=linux; SCRIPT_NAME=test source '$COMMON_SH'; arg_defaults; REMAINING_ARGS=(); parse_common_args --host myhost; [[ \$HOST == 'myhost' ]]"
}
it "parses --host" _t_parse_host

_t_parse_install() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  bash -c "export PLATFORM=linux; SCRIPT_NAME=test source '$COMMON_SH'; arg_defaults; REMAINING_ARGS=(); parse_common_args --install; [[ \$DO_INSTALL -eq 1 ]]"
}
it "parses --install sets DO_INSTALL=1" _t_parse_install

_t_parse_dryrun() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  bash -c "export PLATFORM=linux; SCRIPT_NAME=test source '$COMMON_SH'; arg_defaults; REMAINING_ARGS=(); parse_common_args --install --dry-run; [[ \$DO_INSTALL -eq 0 ]]"
}
it "parses --dry-run overrides --install" _t_parse_dryrun

_t_parse_secrets_subdir() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  bash -c "export PLATFORM=linux; SCRIPT_NAME=test source '$COMMON_SH'; arg_defaults; REMAINING_ARGS=(); parse_common_args --secrets-subdir mysecrets; [[ \$SECRETS_SUBDIR == 'mysecrets' ]]"
}
it "parses --secrets-subdir" _t_parse_secrets_subdir

_t_parse_remaining() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  bash -c "
    export PLATFORM=linux; SCRIPT_NAME=test source '$COMMON_SH'
    arg_defaults; REMAINING_ARGS=()
    parse_common_args --user alice --bogus --another
    [[ \${#REMAINING_ARGS[@]} -eq 2 ]] && [[ \${REMAINING_ARGS[0]} == '--bogus' ]] && [[ \${REMAINING_ARGS[1]} == '--another' ]]
  "
}
it "accumulates unknown flags in REMAINING_ARGS" _t_parse_remaining

# ---------------------------------------------------------------------------
describe "setup_known_hosts"

_t_kh_creates_and_scans() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  local BIN="$T/bin"; mkdir -p "$BIN"
  printf '#!/usr/bin/env bash\nexit 1\n'                             > "$BIN/ssh-keygen";  chmod +x "$BIN/ssh-keygen"
  printf '#!/usr/bin/env bash\necho "github.com ssh-rsa FAKE"\n'    > "$BIN/ssh-keyscan"; chmod +x "$BIN/ssh-keyscan"
  PATH="$BIN:$PATH" HOME="$T/home" bash -c "
    export PLATFORM=linux; SCRIPT_NAME=test source '$COMMON_SH'; setup_known_hosts
  "
  [[ -f "$T/home/.ssh/known_hosts" ]]
}
it "creates SSH dir + known_hosts, calls ssh-keyscan when key absent" _t_kh_creates_and_scans

_t_kh_skips_scan() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  local BIN="$T/bin"; mkdir -p "$BIN"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$BIN/ssh-keygen";  chmod +x "$BIN/ssh-keygen"
  printf '#!/usr/bin/env bash\nexit 1\n' > "$BIN/ssh-keyscan"; chmod +x "$BIN/ssh-keyscan"
  mkdir -p "$T/home/.ssh"; touch "$T/home/.ssh/known_hosts"
  PATH="$BIN:$PATH" HOME="$T/home" bash -c "
    export PLATFORM=linux; SCRIPT_NAME=test source '$COMMON_SH'; setup_known_hosts
  "
}
it "skips ssh-keyscan when key already present" _t_kh_skips_scan

_t_kh_fails_loud() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  local BIN="$T/bin"; mkdir -p "$BIN"
  printf '#!/usr/bin/env bash\nexit 1\n' > "$BIN/ssh-keygen";  chmod +x "$BIN/ssh-keygen"
  printf '#!/usr/bin/env bash\nexit 1\n' > "$BIN/ssh-keyscan"; chmod +x "$BIN/ssh-keyscan"
  mkdir -p "$T/home/.ssh"
  local out; out="$(PATH="$BIN:$PATH" HOME="$T/home" bash -c "
    export PLATFORM=linux; SCRIPT_NAME=test source '$COMMON_SH'; setup_known_hosts
  " 2>&1 || true)"
  [[ "$out" == *"failed"* ]]
}
it "dies with clear message when ssh-keyscan fails" _t_kh_fails_loud

# ---------------------------------------------------------------------------
describe "check_yubikey_age"

_t_yubi_found() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  local BIN="$T/bin"; mkdir -p "$BIN"
  printf '#!/usr/bin/env bash\necho age1yubikey1fakerecipient\n' > "$BIN/age-plugin-yubikey"; chmod +x "$BIN/age-plugin-yubikey"
  PATH="$BIN:$PATH" bash -c "
    export PLATFORM=linux; SCRIPT_NAME=test source '$COMMON_SH'; check_yubikey_age
  "
}
it "passes when age-plugin-yubikey lists a recipient" _t_yubi_found

_t_yubi_missing() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  local BIN="$T/bin"; mkdir -p "$BIN"
  printf '#!/usr/bin/env bash\n' > "$BIN/age-plugin-yubikey"; chmod +x "$BIN/age-plugin-yubikey"
  local out; out="$(PATH="$BIN:$PATH" bash -c "
    export PLATFORM=linux; SCRIPT_NAME=test source '$COMMON_SH'; check_yubikey_age
  " 2>&1 || true)"
  echo "$out" | grep -qi 'no yubikey'
}
it "dies when no recipients found" _t_yubi_missing

# ---------------------------------------------------------------------------
describe "setup_gpg_smartcard"

_t_gpg_enables_ssh_support() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  local BIN="$T/bin"; mkdir -p "$BIN"
  _stub "$BIN" gpgconf
  _stub "$BIN" systemctl
  # gpg stub: list-keys exits 0 (key present), card-status succeeds
  cat > "$BIN/gpg" << 'GEOF'
#!/usr/bin/env bash
exit 0
GEOF
  chmod +x "$BIN/gpg"
  local GNUPGHOME="$T/.gnupg"; mkdir -p "$GNUPGHOME"
  PATH="$BIN:$PATH" HOME="$T" GNUPGHOME="$GNUPGHOME" SUDO="" bash -c "
    export PLATFORM=linux; SCRIPT_NAME=test source '$COMMON_SH'
    GPG_KEY_URL='https://example.com/fake.gpg'
    setup_gpg_smartcard
  "
  grep -qx 'enable-ssh-support' "$GNUPGHOME/gpg-agent.conf"
}
it "writes enable-ssh-support to gpg-agent.conf" _t_gpg_enables_ssh_support

_t_gpg_imports_key_when_absent() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  local BIN="$T/bin"; mkdir -p "$BIN"
  _stub "$BIN" gpgconf
  _stub "$BIN" systemctl
  local CALLS="$T/calls"
  # gpg stub: list-keys exits 1 (key absent), record all calls
  cat > "$BIN/gpg" << GEOF
#!/usr/bin/env bash
echo "gpg \$@" >> "$CALLS"
case "\$1" in
  --list-keys) exit 1 ;;
  *) exit 0 ;;
esac
GEOF
  chmod +x "$BIN/gpg"
  PATH="$BIN:$PATH" HOME="$T" GNUPGHOME="$T/.gnupg" SUDO="" bash -c "
    export PLATFORM=linux; SCRIPT_NAME=test source '$COMMON_SH'
    GPG_KEY_URL='https://example.com/fake.gpg'
    setup_gpg_smartcard
  " 2>/dev/null || true
  grep -q 'fetch-keys' "$CALLS"
}
it "imports GPG key when not in keyring" _t_gpg_imports_key_when_absent

_t_gpg_skips_import_when_present() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  local BIN="$T/bin"; mkdir -p "$BIN"
  _stub "$BIN" gpgconf
  _stub "$BIN" systemctl
  local CALLS="$T/calls"
  # gpg stub: list-keys exits 0 (key present), record all calls
  cat > "$BIN/gpg" << GEOF
#!/usr/bin/env bash
echo "gpg \$@" >> "$CALLS"
exit 0
GEOF
  chmod +x "$BIN/gpg"
  PATH="$BIN:$PATH" HOME="$T" GNUPGHOME="$T/.gnupg" SUDO="" bash -c "
    export PLATFORM=linux; SCRIPT_NAME=test source '$COMMON_SH'
    GPG_KEY_URL='https://example.com/fake.gpg'
    setup_gpg_smartcard
  " 2>/dev/null || true
  ! grep -q 'fetch-keys' "$CALLS"
}
it "skips GPG key import when already in keyring" _t_gpg_skips_import_when_present

_t_gpg_dies_on_missing_card() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  local BIN="$T/bin"; mkdir -p "$BIN"
  _stub "$BIN" gpgconf
  _stub "$BIN" systemctl
  # gpg stub: card-status exits 1 (YubiKey not present)
  cat > "$BIN/gpg" << 'GEOF'
#!/usr/bin/env bash
case "$1" in
  --card-status) exit 1 ;;
  *) exit 0 ;;
esac
GEOF
  chmod +x "$BIN/gpg"
  local out; out="$(PATH="$BIN:$PATH" HOME="$T" GNUPGHOME="$T/.gnupg" SUDO="" bash -c "
    export PLATFORM=linux; SCRIPT_NAME=test source '$COMMON_SH'
    GPG_KEY_URL='https://example.com/fake.gpg'
    setup_gpg_smartcard
  " 2>&1 || true)"
  [[ "$out" == *"YubiKey not detected"* ]]
}
it "dies with clear message when YubiKey not detected" _t_gpg_dies_on_missing_card

_t_gpg_exports_ssh_auth_sock() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  local BIN="$T/bin"; mkdir -p "$BIN"
  _stub "$BIN" systemctl
  # gpgconf stub: return a fake SSH socket path for agent-ssh-socket
  cat > "$BIN/gpgconf" << GEOF
#!/usr/bin/env bash
if [[ "\$*" == *"agent-ssh-socket"* ]]; then
  echo "$T/S.gpg-agent.ssh"
fi
exit 0
GEOF
  chmod +x "$BIN/gpgconf"
  _stub "$BIN" gpg
  local result
  result="$(PATH="$BIN:$PATH" HOME="$T" GNUPGHOME="$T/.gnupg" SUDO="" bash -c "
    export PLATFORM=linux; SCRIPT_NAME=test source '$COMMON_SH'
    GPG_KEY_URL='https://example.com/fake.gpg'
    setup_gpg_smartcard
    echo "\$SSH_AUTH_SOCK"
  " 2>/dev/null || true)"
  [[ "$result" == *"S.gpg-agent.ssh"* ]]
}
it "exports SSH_AUTH_SOCK pointing at gpg-agent SSH socket" _t_gpg_exports_ssh_auth_sock

# ---------------------------------------------------------------------------
describe "clone_or_update_repo"

_t_clone_fresh() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  local BIN="$T/bin"; mkdir -p "$BIN"
  cat > "$BIN/git" << 'GEOF'
#!/usr/bin/env bash
[[ "$1" == clone ]] && mkdir -p "${@: -1}/.git"
exit 0
GEOF
  chmod +x "$BIN/git"
  local DEST="$T/repo"
  PATH="$BIN:$PATH" bash -c "
    export PLATFORM=linux; SCRIPT_NAME=test source '$COMMON_SH'
    clone_or_update_repo label git@x:r.git '$DEST'
  "
  [[ -d "$DEST/.git" ]]
}
it "clones when dest does not exist" _t_clone_fresh

_t_clone_update_no_branch() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  local BIN="$T/bin"; mkdir -p "$BIN"
  local CALLS="$T/calls"
  mkdir -p "$T/repo/.git"
  cat > "$BIN/git" << GEOF
#!/usr/bin/env bash
echo "\$@" >> "$CALLS"
exit 0
GEOF
  chmod +x "$BIN/git"
  PATH="$BIN:$PATH" bash -c "
    export PLATFORM=linux; SCRIPT_NAME=test source '$COMMON_SH'
    clone_or_update_repo label git@x:r.git '$T/repo'
  "
  grep -q 'fetch'  "$CALLS"
  grep -q 'merge'  "$CALLS"
  ! grep -q 'reset --hard' "$CALLS"
}
it "fetches + fast-forwards (no branch), never hard-resets" _t_clone_update_no_branch

_t_clone_update_with_branch() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  local BIN="$T/bin"; mkdir -p "$BIN"
  local CALLS="$T/calls"
  mkdir -p "$T/repo/.git"
  cat > "$BIN/git" << GEOF
#!/usr/bin/env bash
echo "\$@" >> "$CALLS"
exit 0
GEOF
  chmod +x "$BIN/git"
  PATH="$BIN:$PATH" bash -c "
    export PLATFORM=linux; SCRIPT_NAME=test source '$COMMON_SH'
    clone_or_update_repo secrets git@x:s.git '$T/repo' main
  "
  grep -q 'reset --hard origin/main' "$CALLS"
}
it "hard-resets to branch when branch specified" _t_clone_update_with_branch

# ---------------------------------------------------------------------------
describe "decrypt_age_blob"

_t_decrypt_linux() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  local BIN="$T/bin"; mkdir -p "$BIN"
  mkdir -p "$T/secrets/bootstrap"
  echo 'blob' > "$T/secrets/bootstrap/age-keys.txt.age"
  cat > "$BIN/age" << 'AEOF'
#!/usr/bin/env bash
prev=""
for a in "$@"; do
  [[ "$prev" == "-o" ]] && echo "AGE-SECRET-KEY-FAKE" > "$a"
  prev="$a"
done
exit 0
AEOF
  chmod +x "$BIN/age"
  printf '#!/usr/bin/env bash\necho identity\n' > "$BIN/age-plugin-yubikey"; chmod +x "$BIN/age-plugin-yubikey"
  local KEYS_DIR="$T/keys" KEYS_FILE="$T/keys/keys.txt"
  mkdir -p "$KEYS_DIR"
  local BLOB="$T/secrets/bootstrap/age-keys.txt.age"
  T="$T" BIN="$BIN" KEYS_DIR="$KEYS_DIR" KEYS_FILE="$KEYS_FILE" BLOB="$BLOB" \
  PATH="$BIN:$PATH" bash -c "
    export PLATFORM=linux; SCRIPT_NAME=test source '$COMMON_SH'
    SUDO=''
    YUBI_IDENT=\"\$T/yubi.txt\"
    decrypt_age_blob \"\$BLOB\" \"\$KEYS_DIR\" \"\$KEYS_FILE\" 'true'
  "
  [[ -f "$KEYS_FILE" ]]
}
it "linux: decrypts blob, writes key file (root_owned=true)" _t_decrypt_linux

_t_decrypt_missing() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  local out; out="$(bash -c "
    export PLATFORM=linux; SCRIPT_NAME=test source '$COMMON_SH'
    SUDO=''; decrypt_age_blob '/no/blob.age' '/k' '/k/k.txt' 'false'
  " 2>&1 || true)"
  [[ "$out" == *"Missing secrets blob"* ]]
}
it "dies with clear message when blob is missing" _t_decrypt_missing

# ---------------------------------------------------------------------------
describe "install.sh (Linux) — argument handling"
# _NIXOS_BOOTSTRAP_NIX_SHELL=1 bypasses the nix-shell re-exec phase.

_t_linux_rejects_unknown() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  local BIN="$T/bin"; mkdir -p "$BIN"; _common_stubs "$BIN"
  mkdir -p "$T/target"
  local out; out="$(PATH="$BIN:$PATH" HOME="$T" _NIXOS_BOOTSTRAP_NIX_SHELL=1 \
    bash "$INSTALL_LINUX" --target "$T/target" --bogus 2>&1 || true)"
  [[ "$out" == *"nknown argument"* ]]
}
it "rejects unknown flags" _t_linux_rejects_unknown

_t_linux_dest_outside_target() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  local BIN="$T/bin"; mkdir -p "$BIN"; _common_stubs "$BIN"
  mkdir -p "$T/target"
  local out; out="$(PATH="$BIN:$PATH" HOME="$T" _NIXOS_BOOTSTRAP_NIX_SHELL=1 \
    bash "$INSTALL_LINUX" --target "$T/target" --config-dest /tmp/outside --dry-run 2>&1 || true)"
  [[ "$out" == *"not under"* ]]
}
it "rejects --config-dest outside --target" _t_linux_dest_outside_target

_t_linux_dryrun() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  local BIN="$T/bin"; mkdir -p "$BIN"; _common_stubs "$BIN"
  mkdir -p "$T/target/etc" "$T/target/home/rickie" "$T/target/var/lib/age"
  local out; out="$(PATH="$BIN:$PATH" HOME="$T" GNUPGHOME="$T/.gnupg" \
    _NIXOS_BOOTSTRAP_NIX_SHELL=1 \
    bash "$INSTALL_LINUX" --target "$T/target" --host gibson --dry-run 2>&1 || true)"
  [[ "$out" == *"next steps"* ]] || [[ "$out" == *"Next steps"* ]]
}
it "dry-run completes and shows next steps" _t_linux_dryrun

_t_linux_age_path_in_summary() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  local BIN="$T/bin"; mkdir -p "$BIN"; _common_stubs "$BIN"
  mkdir -p "$T/target"
  local out; out="$(PATH="$BIN:$PATH" HOME="$T" _NIXOS_BOOTSTRAP_NIX_SHELL=1 \
    bash "$INSTALL_LINUX" --target "$T/target" 2>&1 || true)"
  [[ "$out" == *"var/lib/age"* ]]
}
it "summary shows Linux age key path (/var/lib/age)" _t_linux_age_path_in_summary

# ---------------------------------------------------------------------------
describe "install-darwin.sh — argument handling"
# _DARWIN_BOOTSTRAP_NIX_SHELL=1 bypasses the nix-shell re-exec phase.

_t_darwin_rejects_unknown() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  local out; out="$(HOME="$T" _DARWIN_BOOTSTRAP_NIX_SHELL=1 \
    bash "$INSTALL_DARWIN" --bogus 2>&1 || true)"
  [[ "$out" == *"nknown argument"* ]]
}
it "rejects unknown flags" _t_darwin_rejects_unknown

_t_darwin_default_host() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  local BIN="$T/bin"; mkdir -p "$BIN"; _common_stubs "$BIN"
  local out; out="$(PATH="$BIN:$PATH" HOME="$T" GNUPGHOME="$T/.gnupg" \
    _DARWIN_BOOTSTRAP_NIX_SHELL=1 \
    bash "$INSTALL_DARWIN" --config-dest "$T/config" --dry-run 2>&1 || true)"
  [[ "$out" == *"macbook"* ]]
}
it "defaults HOST to macbook" _t_darwin_default_host

_t_darwin_age_path() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  local BIN="$T/bin"; mkdir -p "$BIN"; _common_stubs "$BIN"
  local out; out="$(PATH="$BIN:$PATH" HOME="$T" GNUPGHOME="$T/.gnupg" \
    _DARWIN_BOOTSTRAP_NIX_SHELL=1 \
    bash "$INSTALL_DARWIN" --config-dest "$T/config" --dry-run 2>&1 || true)"
  [[ "$out" == *"Library/Application Support/sops/age"* ]]
}
it "age key path matches mk-vars.nix isDarwin branch" _t_darwin_age_path

_t_darwin_dryrun() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  local BIN="$T/bin"; mkdir -p "$BIN"; _common_stubs "$BIN"
  local out; out="$(PATH="$BIN:$PATH" HOME="$T" GNUPGHOME="$T/.gnupg" \
    _DARWIN_BOOTSTRAP_NIX_SHELL=1 \
    bash "$INSTALL_DARWIN" --config-dest "$T/config" --dry-run 2>&1 || true)"
  [[ "$out" == *"next steps"* ]] || [[ "$out" == *"Next steps"* ]]
}
it "dry-run completes and shows next steps" _t_darwin_dryrun

_t_darwin_nix_run_cmd() {
  local T; T="$(mktemp -d)"; trap "rm -rf '$T'" RETURN
  local BIN="$T/bin"; mkdir -p "$BIN"; _common_stubs "$BIN"
  # Provide a nix stub that records its arguments
  printf '#!/usr/bin/env bash\necho "nix: $*"\n' > "$BIN/nix"; chmod +x "$BIN/nix"
  # Stub darwin-rebuild to exit 1 — install-darwin.sh checks with
  # `darwin-rebuild --version` so a failing stub forces the nix run branch.
  printf '#!/usr/bin/env bash\nexit 1\n' > "$BIN/darwin-rebuild"; chmod +x "$BIN/darwin-rebuild"
  local out; out="$(PATH="$BIN:$PATH" HOME="$T" GNUPGHOME="$T/.gnupg" \
    _DARWIN_BOOTSTRAP_NIX_SHELL=1 \
    bash "$INSTALL_DARWIN" --config-dest "$T/config" --install 2>&1 || true)"
  # Verify the correct first-time activation command was used
  [[ "$out" == *"nix-darwin#darwin-rebuild"* ]]
}
it "first-time activation uses nix run nix-darwin#darwin-rebuild" _t_darwin_nix_run_cmd

# ---------------------------------------------------------------------------
echo
echo "=== Bootstrap test suite ==="
summary
