{ infraLib, ... }:
let
  # The overlays themselves (infraLib.overlaysModule, shared with the host
  # registry), and ./_module.nix for the nixpkgs.config they need
  module.imports = [
    (infraLib.overlaysModule ./_overlay-entries.nix)
    ./_module.nix
  ];
in
{
  flake.modules.nixos.overlays = module;
  flake.modules.darwin.overlays = module;

  # Audited alongside each host's own overlays in the overlayAudits flake output
  infra.sharedOverlayEntries."features/core/system/overlays" = ./_overlay-entries.nix;
}
