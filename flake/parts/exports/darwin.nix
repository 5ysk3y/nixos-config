_:
let
  nixosModules = import ./../../../features/system;
in
{
  flake.darwinModules = {
    inherit (nixosModules) core;
  };
}
