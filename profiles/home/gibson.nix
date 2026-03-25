{ inputs, ... }:
{
  imports = [
    inputs.wayland-pipewire-idle-inhibit.homeModules.default
  ];
}
