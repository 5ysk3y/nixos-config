{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.homeManagerModules.default
    inputs.self.modules.homeManager.base
    inputs.self.modules.homeManager.zsh
    inputs.self.modules.homeManager.zoxide
    inputs.self.modules.homeManager.git
    inputs.self.modules.homeManager.gpg
  ];
}
