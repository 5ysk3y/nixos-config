{ inputs, ... }:
{
  imports = [
    (inputs.import-tree ./../../features/home)
  ];
}
