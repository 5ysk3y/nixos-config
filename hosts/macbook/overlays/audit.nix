# Audit metadata for temporary overlays in hosts/macbook/overlays/default.nix.
# Each key must match the overlay identifier used in default.nix.
# Read by flake/parts/exports/overlay-audits.nix and consumed by the
# audit-overlays CI workflow. See flake.overlayAudits for option definitions.
{
  qtwebengine = {
    strategy = "nixpkgs-pr";
    description = "Darwin qt6.qtwebengine build fix, pending upstream PR merge";
    systems = [ "aarch64-darwin" ];
    trackingPRs = [
      {
        repo = "NixOS/nixpkgs";
        number = 515997;
      }
    ];
    notes = "COUPLED REMOVAL: also remove qtwebengine-fix flake input from flake.nix and the qtPinnedPkgs let-binding in hosts/macbook/overlays/default.nix.";
  };
}
