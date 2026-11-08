# My SSH public keys, for any machine that lets me log in. Read-only data:
# importing this sets nothing on its own.
{ lib, ... }:
{
  options.features.system.sshKeys.yubikeys = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    readOnly = true;
    # The SSH form of each YubiKey's GPG authentication subkey, from the
    # public keys in features/core/home's 5ysk3y.asc
    # (`gpg --export-ssh-key <subkey>!`). gpg-agent offers them for SSH.
    # Update these when an auth subkey changes; the second one expires
    # 2028-02-08.
    default = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN5MSEmSVl4I5cAAjdw1TcSJyXTfTOAoWFPsW4hH0cEn openpgp:0xC72D5515"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINnG3kLExbeEa+9lJcrNpVBlT/t2MvTZe9ujRHaMv9uC openpgp:0xF37EDB04"
    ];
    description = "Both YubiKeys' SSH public keys.";
  };
}
