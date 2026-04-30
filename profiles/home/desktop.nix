{ inputs, pkgs, ... }:
{
  imports = [
    # Home-Manager
    inputs.wayland-pipewire-idle-inhibit.homeModules.default
    inputs.self.modules.homeManager.doomemacs
    inputs.self.modules.homeManager.fuzzel
    inputs.self.modules.homeManager.gaming
    inputs.self.modules.homeManager.github-cli
    inputs.self.modules.homeManager.gtk-dracula
    inputs.self.modules.homeManager.hypr
    inputs.self.modules.homeManager.kitty
    inputs.self.modules.homeManager.mako
    inputs.self.modules.homeManager.media
    inputs.self.modules.homeManager.nix-settings
    inputs.self.modules.homeManager.obs-studio
    inputs.self.modules.homeManager.password-management
    inputs.self.modules.homeManager.playerctld
    inputs.self.modules.homeManager.qutebrowser
    inputs.self.modules.homeManager.sops-nix
    inputs.self.modules.homeManager.symlinks
    inputs.self.modules.homeManager.waybar
    inputs.self.modules.homeManager.wayland-idle-inhibit
    inputs.self.modules.homeManager.xdg-portal-hyprland
    inputs.self.modules.homeManager.syncthing
  ];

  home.packages = [
    inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.dim-screen
  ];
}
