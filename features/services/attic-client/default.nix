_: {
  flake.modules = {
    nixos.attic-client = ./_nixos.nix;
    darwin.attic-client = ./_darwin.nix;
    homeManager.attic-client = ./_home.nix;
  };
}
