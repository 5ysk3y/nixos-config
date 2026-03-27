_:
let
  nix-modules = import ./../../../features/nixos;
in
{
  flake.darwinModules = {
    inherit (nix-modules) core;
  };
}
