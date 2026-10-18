# sets a nixpkgs policy for hosts, supplementary sets and perSystem outputs.
{ inputs, ... }:
let
  nixpkgsConfig = {
    allowUnfree = true;
  };
in
{
  _module.args.nixpkgsConfig = nixpkgsConfig;

  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config = nixpkgsConfig;
      };
    };
}
