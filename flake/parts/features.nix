{
  imports = [

    # home-manager - core modules
    ./../../features/home/core/base.nix
    ./../../features/home/core/git.nix
    ./../../features/home/core/gpg.nix
    ./../../features/home/core/zoxide.nix
    ./../../features/home/core/zsh.nix

    # home-manager - main modules
    ./../../features/home/doomemacs
    ./../../features/home/fuzzel
    ./../../features/home/gaming
    ./../../features/home/gtk-dracula
    ./../../features/home/hypr
    ./../../features/home/kitty
    ./../../features/home/mako
    ./../../features/home/media
    ./../../features/home/nix-settings
    ./../../features/home/obs-studio
    ./../../features/home/password-management
    ./../../features/home/playerctld
    ./../../features/home/qutebrowser
    ./../../features/home/sops-nix
    ./../../features/home/symlinks
    ./../../features/home/waybar
    ./../../features/home/wayland-idle-inhibit
    ./../../features/home/xdg-portal-hyprland
  ];
}
