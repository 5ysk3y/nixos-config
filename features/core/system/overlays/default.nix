_: {
  flake.modules.nixos.overlays = ./_module.nix;
  flake.modules.darwin.overlays = ./_module.nix;

  # Audited alongside each host's own overlays in the overlayAudits flake output
  infra.sharedOverlayEntries."features/core/system/overlays" = ./_overlay-entries.nix;
}
