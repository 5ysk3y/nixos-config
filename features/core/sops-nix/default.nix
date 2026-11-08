_: {
  flake = {
    modules = {
      nixos.sops-nix = ./_nixos.nix;
      darwin.sops-nix = ./_system.nix;
      homeManager.sops-nix = ./_home.nix;
    };
  };
}
