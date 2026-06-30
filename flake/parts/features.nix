{ inputs, ... }:
{
  imports = [
    (inputs.import-tree ./../../features/home)
    (inputs.import-tree ./../../features/system)
  ];
}
