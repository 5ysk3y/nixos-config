#!/usr/bin/env bash
TARGET="root@192.168.1.110"

push_secrets() {
  SECRETS_PATH="$(nix eval --impure --raw --expr '(builtins.getFlake (toString ./.)).inputs.nix-secrets.outPath')"
  SECRETS_FILE="$SECRETS_PATH/secrets/secrets.yaml"
  sops --decrypt --extract '["services"]["attic"]["server-token"]' "$SECRETS_FILE" \
    | ssh "${SSH_OPTS[@]}" "$TARGET" 'install -m 0600 /dev/stdin /var/lib/attic/env'
}
