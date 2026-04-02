{ lib, ... }:
{
  options.flake.modules = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.anything);
    default = { };
    description = "Custom exported module collections.";
  };
}
