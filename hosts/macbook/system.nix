# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  lib,
  pkgs,
  vars,
  ...
}:
{

  networking.hostName = "macbook"; # Define your hostname.

  nix = {
    enable = false;
  };

  users.users.${vars.username} = {
    home = "/Users/${vars.username}";
    shell = pkgs.zsh;
  };

  environment = {
    systemPackages = [ ];
    etc = {
      "nix/nix.custom.conf" = {
        text = ''
          experimental-features = nix-command flakes
        '';
      };
    };
  };

  services.openssh.enable = false;

  system = {
    stateVersion = 5;
    primaryUser = "${vars.username}";
  };
}
