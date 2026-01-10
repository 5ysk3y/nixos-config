# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  config,
  lib,
  pkgs,
  vars,
  ...
}:
{
  networking.hostName = "macbook"; # Define your hostname.
  
  # Set your time zone.
  time.timeZone = "Europe/London";

  nix = {
    enable = false;
  };

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${vars.username} = {
    home = "/Users/${vars.username}";
    shell = pkgs.zsh;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
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

  #security = {
  #  pki = {
  #    certificates = [
  #      (builtins.readFile ../../certs/root-ca.crt)
  #    ];
  #  };
  #};

  # Enable the OpenSSH daemon.
  services.openssh.enable = false;

  system.stateVersion = 5;
}
