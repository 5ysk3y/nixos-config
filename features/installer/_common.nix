{ pkgs, ... }:
let
  # The SSH form of each YubiKey's GPG authentication subkey, from the public
  # keys in home-core's 5ysk3y.asc (`gpg --export-ssh-key <subkey>!`). Lets
  # either key log in to the live system for a remote install. Update these
  # when an auth subkey changes; the second one expires 2028-02-08.
  yubikeySshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN5MSEmSVl4I5cAAjdw1TcSJyXTfTOAoWFPsW4hH0cEn openpgp:0xC72D5515"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINnG3kLExbeEa+9lJcrNpVBlT/t2MvTZe9ujRHaMv9uC openpgp:0xF37EDB04"
  ];
in
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # YubiKey: pcscd for age-plugin-yubikey (PIV), gpg-agent for SSH via the
  # OpenPGP applet. disable-ccid leaves the card to pcscd so both can use it,
  # as on gibson (hosts/personal/gibson/home.nix). scdaemon reads this
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
