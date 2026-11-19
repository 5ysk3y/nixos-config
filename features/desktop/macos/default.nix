_: {
  flake.modules = {
    darwin.macos = ./_darwin.nix;
    homeManager.macos = ./_home.nix;
  };
}
