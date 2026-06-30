_: {
  flake.modules.nixos.overlays = ./_module.nix;
  flake.modules.darwin.overlays = ./_module.nix;
}
