_:
let
  entries = import ./_overlay-entries.nix { };
in
{
  nixpkgs.overlays = [
    entries.permanent
  ]
  ++ (map (e: e.overlay) entries.tracked);

  # nixpkgs.config definitions merge with recursiveUpdate, which replaces
  # lists rather than concatenating them: keep this the only module that sets
  # permittedInsecurePackages, or one definition silently drops the other.
  nixpkgs.config.permittedInsecurePackages = builtins.concatMap (
    e: e.permittedInsecurePackages or [ ]
  ) entries.tracked;
}
