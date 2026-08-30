{
  inputs,
  mkVars,
  username,
}:
{
  gibson = import ./personal/gibson.nix { inherit inputs mkVars username; };
  macbook = import ./personal/macbook.nix { inherit inputs mkVars username; };
  attic = import ./servers/attic.nix { inherit inputs mkVars username; };
}
