# Host-specific config for bootstrap/deploy.sh thevault
#
# TARGET defaults to the permanent address, but the very first deploy must
# override it: at that point the container is still reachable at the
# staging IP (192.168.1.150), not .9 — system.nix's static address only
# takes effect *during* that first activation, so targeting .9 before then
# has nothing to reach. Run the one-time bootstrap as:
#   TARGET=root@192.168.1.150 bootstrap/deploy.sh thevault
# Every deploy after that uses the default below unmodified.
TARGET="${TARGET:-root@192.168.1.9}"

# Hard requirement: this deploy must never run before the real Vaultwarden
# database is already in place, or the first successful service start
# creates a fresh, empty one — see chat, this replaced an earlier
# stop-the-service-after-first-start plan that carried real risk.
preflight_check() {
  echo "==> checking ${TARGET} is reachable"
  if ! ssh "${SSH_OPTS[@]}" -o ConnectTimeout=5 "$TARGET" 'true' 2>/dev/null; then
    echo "error: ${TARGET} is not reachable over SSH." >&2
    echo "       Expected if the real container hasn't been created/booted" >&2
    echo "       yet, or if this is the first-ever deploy and TARGET wasn't" >&2
    echo "       overridden to the staging IP (192.168.1.150) — see the" >&2
    echo "       comment above TARGET in this file." >&2
    exit 1
  fi
  echo "==> checking for existing Vaultwarden data on ${TARGET}"
  if ! ssh "${SSH_OPTS[@]}" "$TARGET" 'test -f /var/lib/vaultwarden/db.sqlite3'; then
    echo "error: /var/lib/vaultwarden/db.sqlite3 not found on ${TARGET}." >&2
    echo "       Copy the real database + rsa_key files across before" >&2
    echo "       running this deploy — see the migration plan. Refusing" >&2
    echo "       to proceed: a first successful service start against an" >&2
    echo "       empty data folder creates a fresh database." >&2
    exit 1
  fi
}

push_secrets() {
  SECRETS_PATH="$(nix eval --impure --raw --expr '(builtins.getFlake (toString ./.)).inputs.nix-secrets.outPath')"
  # mkdir defensively rather than relying on deploy ordering vs. the
  # tmpfiles.rules declaration in features/vaultwarden/_module.nix — on a
  # genuinely fresh host, push_secrets runs before the first switch has
  # ever created this directory.
  ssh "${SSH_OPTS[@]}" "$TARGET" 'mkdir -p -m 0700 /var/lib/vaultwarden-secrets'
  sops --decrypt "$SECRETS_PATH/secrets/vaultwarden/theVault.env" \
    | ssh "${SSH_OPTS[@]}" "$TARGET" 'install -m 0600 /dev/stdin /var/lib/vaultwarden-secrets/env'
  sops --decrypt "$SECRETS_PATH/secrets/vaultwarden/restic.password" \
    | ssh "${SSH_OPTS[@]}" "$TARGET" 'install -m 0600 /dev/stdin /var/lib/vaultwarden-secrets/restic-password'
  sops --decrypt "$SECRETS_PATH/secrets/vaultwarden/restic-sftp.key" \
    | ssh "${SSH_OPTS[@]}" "$TARGET" 'install -m 0600 /dev/stdin /var/lib/vaultwarden-secrets/restic-sftp-key'
}
