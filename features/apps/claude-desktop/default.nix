# Claude Desktop (Linux only: Anthropic's apt repo has no macOS build).
# The desktop profiles import both modules.
{ infraLib, ... }:
{
  flake.modules = {
    # The system side applies the package's temporary overlay, on purpose at
    # system level: with home-manager.useGlobalPkgs = true, an
    # nixpkgs.overlays set in a Home Manager module has no effect. It also
    # writes the managed policy that turns off the app's update checks
    # (./_nixos.nix), which the app reads only from /etc.
    nixos.claude-desktop.imports = [
      (infraLib.overlaysModule ./_overlay-entries.nix)
      ./_nixos.nix
    ];
    homeManager.claude-desktop = ./_home.nix;
  };

  # Audited alongside each host's own overlays in the overlayAudits flake output
  infra.sharedOverlayEntries."features/apps/claude-desktop" = ./_overlay-entries.nix;
}
