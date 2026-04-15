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

  launchd.user.agents.emacs-daemon = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.emacs}/bin/emacs"
        "--fg-daemon"
      ];
      EnvironmentVariables = {
        PATH = lib.concatStringsSep ":" [
          "/etc/profiles/per-user/${vars.username}/bin"
          "/run/current-system/sw/bin"
          "/nix/var/nix/profiles/default/bin"
          "/usr/bin"
          "/bin"
          "/usr/sbin"
          "/sbin"
        ];
        TERMINFO_DIRS = lib.concatStringsSep ":" [
          "${pkgs.ghostty-bin.terminfo}/share/terminfo"
          "${pkgs.ncurses.out}/share/terminfo"
          "/usr/share/terminfo"
          "/etc/terminfo"
        ];
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
