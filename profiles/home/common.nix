{ config, ... }:
{
  infra.profiles.homeManager.common = {
    imports = with config.flake.modules.homeManager; [
      base
      git
      gpg
      nix-settings
      zsh
      zoxide
    ];
  };
}
