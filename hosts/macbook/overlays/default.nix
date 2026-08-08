{ inputs, pkgs, ... }:
let
  entries = import ./overlay-entries.nix { inherit inputs pkgs; };
in
{
  nixpkgs.overlays = [
    entries.permanent
  ]
  ++ (map (e: e.overlay) entries.tracked);
}
