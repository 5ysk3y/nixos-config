# Home configuration for the Linux desktop
{ config, inputs, ... }:
{
  infra.profiles.homeManager.desktop =
    { pkgs, ... }:
    {
      imports = [
        inputs.wayland-pipewire-idle-inhibit.homeModules.default
      ]
      ++ (with config.flake.modules.homeManager; [
        fuzzel
        gaming
        hypr
        kitty
        mako
        media
        messaging
        obs-studio
        password-management
        playerctld
        waybar
        wayland-idle-inhibit
      ]);

      home.packages = [
        inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.dim-screen
      ];
    };
}
