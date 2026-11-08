_: {
  flake.modules = {
    homeManager = {
      hypr = ./_module.nix;
      xdg-portal-hyprland = ./_portal.nix;
    };
    nixos.hypr = ./_system.nix;
  };
}
