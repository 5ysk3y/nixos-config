{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.homeManagerModules.default
    inputs.self.homeManagerModules.commonConfig
  ];
}
