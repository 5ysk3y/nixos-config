_: {
  flake.modules.nixos.user = ./_nixos.nix;
  flake.modules.darwin.user = ./_darwin.nix;
}
