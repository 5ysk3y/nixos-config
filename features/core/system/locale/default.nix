_: {
  flake.modules.nixos.locale = ./_nixos.nix;
  flake.modules.darwin.locale = ./_module.nix;
}
