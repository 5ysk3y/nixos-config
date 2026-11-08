{ lib, pkgs, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;

  # Vendored copy of https://github.com/5ysk3y.gpg — avoids a network fetch
  # at eval time, and eval breaking whenever GitHub's copy changes. Update
  # it deliberately when the key (or a subkey) changes.
  ghKey = ./files/5ysk3y.asc;
in
{
  programs.gpg = {
    enable = true;

    # On Linux, scdaemon reaches the YubiKey through pcscd
    # (features/core/yubikey) instead of claiming the reader itself, so
    # age-plugin-yubikey (PIV, through pcscd) and gpg can both use it
    scdaemonSettings = lib.mkIf isLinux { disable-ccid = true; };

    publicKeys = [
      {
        source = ghKey;
        trust = 5;
      }
    ];
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    defaultCacheTtl = 600;
    maxCacheTtl = 7200;
    pinentry.package = if isDarwin then pkgs.pinentry_mac else pkgs.pinentry-curses;
  };
}
