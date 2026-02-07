{
  core = import ./core;

  core-nix = import ./core/nix.nix;
  core-locale = import ./core/locale.nix;
  core-security = import ./core/security.nix;

  containers = import ./containers;

  containers-pentesting = import ./containers/pentesting;
}
