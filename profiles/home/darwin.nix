{ config, inputs, ... }:
{
  infra.profiles.homeManager.darwin = {
    imports = [
      inputs.stylix.homeModules.stylix
      inputs.mac-app-util.homeManagerModules.default
    ]
    ++ (with config.flake.modules.homeManager; [
      claude-code
      doomemacs
      ghostty
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
