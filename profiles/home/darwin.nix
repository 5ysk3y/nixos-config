# Home configuration for macOS
{ config, inputs, ... }:
{
  infra.profiles.homeManager.darwin = {
    imports = [
      inputs.mac-app-util.homeManagerModules.default
    ]
    ++ (with config.flake.modules.homeManager; [
      ghostty
    ]);
  };
}
