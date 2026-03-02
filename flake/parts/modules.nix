_:
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
      inherit (nix-modules) core;
    };
  };
}
