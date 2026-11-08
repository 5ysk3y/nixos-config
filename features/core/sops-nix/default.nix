_: {
  flake = {
    modules = {
      nixos.sops-nix = ./_system.nix;
      darwin.sops-nix = ./_system.nix;
      homeManager.sops-nix = ./_home.nix;
    };
  };
}
