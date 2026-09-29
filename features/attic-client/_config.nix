# attic reads $XDG_CONFIG_HOME/attic/config.toml. token-file makes it read the
# sops-decrypted token itself, so the token never appears in a process's
# arguments (as `attic login home <url> <token>` would put it) or in a
# plaintext config written by `attic login`.
{ pkgs, tokenFile }:
pkgs.linkFarm "attic-watch-store-config" {
  "attic/config.toml" = (pkgs.formats.toml { }).generate "attic-config.toml" {
    default-server = "home";
    servers.home = {
      endpoint = "https://attic.home.arpa";
      token-file = tokenFile;
    };
  };
}
