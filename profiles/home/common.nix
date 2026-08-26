{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.modules.homeManager.base
    inputs.self.modules.homeManager.git
    inputs.self.modules.homeManager.gpg
    inputs.self.modules.homeManager.nix-settings
    inputs.self.modules.homeManager.zsh
    inputs.self.modules.homeManager.zoxide
  ];
}
