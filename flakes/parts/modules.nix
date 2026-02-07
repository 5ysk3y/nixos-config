{ ... }:
let
  nix-modules = import ./../../nixosModules;
in
{
  flake = {
    homeManagerModules = {
      default = import ./../../home/modules;
      commonConfig = import ./../../home/user/common.nix;
    };

    nixosModules = nix-modules;
    darwinModules = {
      core = nix-modules.core;
    };
  };
}
