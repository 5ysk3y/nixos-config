{ inputs, ... }:
let
  entries = import ./overlay-entries.nix { inherit inputs; };
in
{
  nixpkgs.overlays = [
    entries.permanent
  ]
  ++ (map (e: e.overlay) entries.tracked);
}
