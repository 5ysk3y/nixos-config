# The Linux desktop's smaller pieces. Hyprland, Waybar and SDDM live in
# subdirectories here, each registering itself.
{ inputs, ... }: {
  flake.modules = {
    homeManager = {
      dimland = {
        imports = [
          inputs.dimland.homeManagerModules.dimland
          ./_dimland.nix
        ];
      };
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
