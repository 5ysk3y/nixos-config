_: {
  flake.modules.nixos.security = ./_common.nix;
  flake.modules.darwin.security = ./_darwin.nix;
}
