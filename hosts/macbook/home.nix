{
  config,
  lib,
  ...
}:
{
  imports = [
    ../../home/modules
    ../../home/user/common.nix
    ../../home/user/macbook.nix
  ];
}
