# The machines I use directly (gibson, macbook): secrets, the tailnet, the
# attic cache's push units, and Claude Code
{ config, ... }:
let
  personal =
    class: with config.flake.modules.${class}; [
      attic-client
      claude-code
      sops-nix
      tailscale
    ];
in
{
  infra.profiles = {
    nixos.personal.imports = personal "nixos" ++ [ config.flake.modules.nixos.yubikey ];
    darwin.personal.imports = personal "darwin";
  };
}
