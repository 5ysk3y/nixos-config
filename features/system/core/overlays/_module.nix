_:
let
  entries = import ./_overlay-entries.nix { };
in
{
  nixpkgs.overlays = [
    entries.permanent
  ]
  ++ (map (e: e.overlay) entries.tracked);
}
