{ vars, pkgs, ... }:
{
  home = {
    inherit (vars) username;

    packages = with pkgs; [
      bat
    ];

    sessionVariables = {
      GIT_AUTO_FETCH_INTERVAL = 1200;
      NIXOS_CONFIG = "$HOME/nixos-config";
    };

    stateVersion = "23.11";
  };

  programs.home-manager.enable = true;
}
