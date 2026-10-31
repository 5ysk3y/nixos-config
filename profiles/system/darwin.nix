{ config, ... }:
{
  infra.profiles.darwin.darwin = {
    imports = with config.flake.modules.darwin; [
      attic-client
      claude-code
      editor
      linux-builder
      locale
      nix-settings
      overlays
      security
      sops-nix
      tailscale
    ];
  };
}
