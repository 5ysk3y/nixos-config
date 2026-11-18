# shellcheck shell=bash
# Host-specific config for bootstrap/deploy.sh attic, which sources this
# file and reads TARGET
# shellcheck disable=SC2034
TARGET="root@192.168.1.110"

push_secrets() {
  SECRETS_PATH="$(nix eval --impure --raw --expr '(builtins.getFlake (toString ./.)).inputs.nix-secrets.outPath')"
  SECRETS_FILE="$SECRETS_PATH/secrets/secrets.yaml"
  sops --decrypt --extract '["services"]["attic"]["server-token"]' "$SECRETS_FILE" \
    | push_secret /var/lib/attic/env atticd.service
}
