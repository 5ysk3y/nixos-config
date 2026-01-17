{
  config,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ../../home/modules
    ../../home/users/rickie/common.nix
    ../../home/users/rickie/gibson.nix
    inputs.wayland-pipewire-idle-inhibit.homeModules.default
  ];
}
