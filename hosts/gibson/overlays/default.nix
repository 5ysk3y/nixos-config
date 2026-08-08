{ inputs, ... }:
let
  entries = import ./overlay-entries.nix { inherit inputs; };
in
{
  nixpkgs.overlays = [
    # claude-code-nix: must be applied at system level — nixpkgs.overlays set
    # inside HM modules has no effect when useGlobalPkgs = true.
    inputs.claude-code-nix.overlays.default
    inputs.self.overlays.default
    entries.permanent
  ]
  ++ (map (e: e.overlay) entries.tracked);
}
