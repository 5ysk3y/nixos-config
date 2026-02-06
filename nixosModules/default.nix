{
  core = {
    nix = import ./core/nix.nix;
    locale = import ./core/locale.nix;
    security = import ./core/security.nix;
  };

  containers = import ./containers;
}
