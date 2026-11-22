# Home configuration for the machines I use directly (gibson, macbook)
{ config, inputs, ... }:
{
  infra.profiles.homeManager.personal = {
    imports = [
      inputs.stylix.homeModules.stylix
    ]
    ++ (with config.flake.modules.homeManager; [
      bitwarden
      claude-code
      doomemacs
      github-cli
      hugo
      media
      messaging
      password-management
      qutebrowser
      rbw
      sops-nix
      stylix
      syncthing
    ]);
  };
}
