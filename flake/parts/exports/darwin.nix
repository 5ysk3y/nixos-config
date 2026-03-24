_:
let
  nix-modules = import ./../../../nixosModules;
in
{
  flake.darwinModules = {
    inherit (nix-modules) core;
  };
}
