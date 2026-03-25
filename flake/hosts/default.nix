{
  inputs,
  mkVars,
  username,
}:
{
  gibson = import ./gibson.nix {
    inherit
      inputs
      mkVars
      username
      ;
  };

  macbook = import ./macbook.nix {
    inherit
      inputs
      mkVars
      username
      ;
  };
}
