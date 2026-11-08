# Home configuration for the machines I use directly (gibson, macbook)
{ config, inputs, ... }:
{
  infra.profiles.homeManager.personal = {
    imports = [
      inputs.stylix.homeModules.stylix
    ]
    ++ (with config.flake.modules.homeManager; [
      claude-code
      doomemacs
      github-cli
      hugo
      qutebrowser
      sops-nix
      stylix
      symlinks
      syncthing
    ]);
  };
}
