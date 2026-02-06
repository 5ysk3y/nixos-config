# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  config,
  lib,
  pkgs,
  vars,
  inputs,
  ...
}:
{

  imports = [
    inputs.self.darwinModules.core
  ];

  networking.hostName = "macbook"; # Define your hostname.

  # Set your time zone.
  time.timeZone = "Europe/London";

  nix = {
    enable = false;
  };

  users.users.${vars.username} = {
    home = "/Users/${vars.username}";
    shell = pkgs.zsh;
  };

  environment.systemPackages = with pkgs; [
  ];

  environment = {
    etc = {
      "nix/nix.custom.conf" = {
        text = ''
          experimental-features = nix-command flakes
        '';
      };
    };
    variables = {
    };
  };

  services.openssh.enable = false;

  system.stateVersion = 5;
}
