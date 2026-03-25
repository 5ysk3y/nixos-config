{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.core
    inputs.self.nixosModules.containers
  ];
}
