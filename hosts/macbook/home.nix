{
  config,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ../../home/user/macbook.nix
    inputs.self.homeManagerModules.default
    inputs.self.homeManagerModules.commonConfig
    inputs.mac-app-util.homeManagerModules.default
  ];
}
