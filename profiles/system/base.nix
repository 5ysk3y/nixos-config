# Every machine, NixOS and darwin alike
{ config, ... }:
let
  base =
    class: with config.flake.modules.${class}; [
      editor
      locale
      nix-settings
      overlays
      security
    ];
in
{
  infra.profiles = {
    nixos.base.imports = base "nixos";
    darwin.base.imports = base "darwin";
  };
}
