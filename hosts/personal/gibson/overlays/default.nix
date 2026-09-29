{ inputs, ... }:
let
  entries = import ./overlay-entries.nix { inherit inputs; };
in
{
  nixpkgs.overlays = [
    inputs.self.overlays.default
    entries.permanent
  ]
  ++ (map (e: e.overlay) entries.tracked);
}
