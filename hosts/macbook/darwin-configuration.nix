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

  networking.hostName = "macbook"; # Define your hostname.

  nix = {
    enable = false;
  };

  users.users.${vars.username} = {
    home = "/Users/${vars.username}";
    shell = pkgs.zsh;
  };

  environment = {
    systemPackages = with pkgs; [ ];
    etc = {
      "nix/nix.custom.conf" = {
        text = ''
          experimental-features = nix-command flakes
        '';
      };
    };
  };

  services.openssh.enable = false;

  launchd.user.agents.emacs-daemon = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.emacs}/bin/emacs"
        "--fg-daemon"
      ];
      EnvironmentVariables = {
        TERMINFO_DIRS =
          "/Applications/Ghostty.app/Contents/Resources/terminfo:"
          + "${pkgs.ncurses.out}/share/terminfo:"
          + "/usr/share/terminfo:/etc/terminfo";
      };

      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/emacs-daemon.log";
      StandardErrorPath = "/tmp/emacs-daemon.err";
    };
  };

  system = {
    stateVersion = 5;
    primaryUser = "${vars.username}";
  };
}
