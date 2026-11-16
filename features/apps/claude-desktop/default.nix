# Claude Desktop (Linux only: Anthropic's apt repo has no macOS build).
# A host opts in by importing both modules.
_: {
  flake.modules = {
    nixos.claude-desktop = ./_nixos.nix;
    homeManager.claude-desktop = ./_home.nix;
  };

  # Audited alongside each host's own overlays in the overlayAudits flake output
  infra.sharedOverlayEntries."features/apps/claude-desktop" = ./_overlay-entries.nix;
}
