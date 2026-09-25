{ config, inputs, ... }:
{
  infra.profiles.homeManager.desktop =
    { pkgs, ... }:
    {
      imports = [
        inputs.wayland-pipewire-idle-inhibit.homeModules.default
        inputs.stylix.homeModules.stylix
      ]
      ++ (with config.flake.modules.homeManager; [
        claude-code
        doomemacs
        fuzzel
        gaming
        github-cli
        hypr
        hugo
        kitty
        mako
        media
        obs-studio
        password-management
        playerctld
        qutebrowser
        sops-nix
        stylix
        symlinks
        waybar
        wayland-idle-inhibit
        xdg-portal-hyprland
        syncthing
      ]);

      home.packages = [
        inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.dim-screen
      ];
    };
}
