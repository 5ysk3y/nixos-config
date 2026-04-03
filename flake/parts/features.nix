{
  imports = [

    # home-manager - shared config
    ./../../features/home/shared/base.nix
    ./../../features/home/shared/git.nix
    ./../../features/home/shared/gpg.nix
    ./../../features/home/shared/zoxide.nix
    ./../../features/home/shared/zsh.nix

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
