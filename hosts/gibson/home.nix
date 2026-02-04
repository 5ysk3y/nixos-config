{
  config,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ../../home/user/gibson.nix
    inputs.wayland-pipewire-idle-inhibit.homeModules.default
    inputs.self.homeManagerModules.default
    inputs.self.homeManagerModules.commonConfig
  ];
}
