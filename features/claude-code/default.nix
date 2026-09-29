{ inputs, ... }:
let
  # System level on purpose: with home-manager.useGlobalPkgs = true, an
  # nixpkgs.overlays set in a Home Manager module has no effect.
  overlay = {
    nixpkgs.overlays = [ inputs.claude-code-nix.overlays.default ];
  };
in
{
  flake.modules = {
    homeManager.claude-code = ./_module.nix;
    nixos.claude-code = overlay;
    darwin.claude-code = overlay;
  };
}
