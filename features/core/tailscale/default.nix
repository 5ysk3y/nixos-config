_: {
  flake.modules.nixos.tailscale = ./_nixos.nix;
  flake.modules.darwin.tailscale = ./_darwin.nix;
}
