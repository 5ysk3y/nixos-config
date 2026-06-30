_: {
  flake.modules.nixos.security = ./_module.nix;
  flake.modules.darwin.security = ./_module.nix;
}
