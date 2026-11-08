# The Linux desktop's smaller pieces. Hyprland, Waybar and SDDM live in
# subdirectories here, each registering itself.
_: {
  flake.modules = {
    homeManager = {
      fuzzel = ./_fuzzel.nix;
      mako = ./_mako.nix;
      playerctld = ./_playerctld.nix;
      wayland-idle-inhibit = ./_idle-inhibit.nix;
    };

    nixos = {
      desktop-services = ./_services.nix;
      fonts = ./_fonts.nix;
    };
  };
}
