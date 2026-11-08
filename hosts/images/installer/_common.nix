{ config, pkgs, ... }:
let
  # Either YubiKey can log in to the live system for a remote install
  yubikeySshKeys = config.features.system.sshKeys.yubikeys;
in
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # YubiKey: pcscd for age-plugin-yubikey (PIV), gpg-agent for SSH via the
  # OpenPGP applet. disable-ccid leaves the card to pcscd so both can use it,
  # as on gibson (features/core/home/_gpg.nix). scdaemon reads this
  # system-wide file before ~/.gnupg/scdaemon.conf.
  services.pcscd.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  environment.etc."gnupg/scdaemon.conf".text = ''
    disable-ccid
  '';

  environment.systemPackages = with pkgs; [
    age
    age-plugin-yubikey
    disko
    git
    yubikey-manager
  ];

  # The installer profile already runs sshd, and the live accounts have
  # empty passwords: allow these keys only, with no password-style login.
  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
  };
  users.users.root.openssh.authorizedKeys.keys = yubikeySshKeys;
  users.users.nixos.openssh.authorizedKeys.keys = yubikeySshKeys;
}
