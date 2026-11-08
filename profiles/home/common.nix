# Home configuration for every machine with Home Manager: shell, git, GPG,
# Nix tooling
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
