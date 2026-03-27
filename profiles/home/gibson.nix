{ inputs, pkgs, ... }:
{
  imports = [
    inputs.wayland-pipewire-idle-inhibit.homeModules.default
  ];

  home.packages = [
    inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.dim-screen
  ];
}
