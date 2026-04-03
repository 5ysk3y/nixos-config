{ inputs, ... }:
{
  imports = [
    inputs.mac-app-util.homeManagerModules.default
    inputs.self.modules.homeManager.doomemacs
    inputs.self.modules.homeManager.qutebrowser
    inputs.self.modules.homeManager.symlinks
  ];
}
