_:

{
  # Note: the claude-code-nix overlay is applied at the NixOS system level in
  # hosts/gibson/overlays/default.nix — setting nixpkgs.overlays here has no
  # effect when home-manager.useGlobalPkgs = true and will become an error.
  programs = {
    claude-code = {
      enable = true;
    };
  };
}
