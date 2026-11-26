# Gives Claude Desktop somewhere to keep its sign-in.
#
# The app encrypts its OAuth tokens with Electron's safeStorage. On Linux,
# safeStorage needs a Secret Service on D-Bus. Without one it falls back to
# "basic_text", and the app then refuses to write the tokens to disk. So
# every restart asked for a fresh sign-in. gnome-keyring provides that
# Secret Service. The login PAM stack, which SDDM's includes, unlocks it
# with the login password. ./_home.nix tells the app to use it.
#
# A YubiKey login (pam_u2f, features/core/yubikey) gives PAM no password,
# so after one the keyring asks for its password on first use.
_: {
  services.gnome.gnome-keyring.enable = true;

  # gnome-keyring turns on gcr's SSH agent by default, which would take
  # SSH_AUTH_SOCK from gpg-agent and its YubiKey SSH keys
  services.gnome.gcr-ssh-agent.enable = false;
}
