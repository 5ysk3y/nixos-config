{
  config,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ../../home/modules
    ../../home/user/common.nix
    ../../home/user/gibson.nix
    inputs.wayland-pipewire-idle-inhibit.homeModules.default
  ];
}
