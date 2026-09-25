_: {
  flake.modules.nixos.overlays = ./_module.nix;
  flake.modules.darwin.overlays = ./_module.nix;

  # Audited alongside each host's own overlays in the overlayAudits flake output
  infra.sharedOverlayEntries."features/system-core/overlays" = ./_overlay-entries.nix;
}
