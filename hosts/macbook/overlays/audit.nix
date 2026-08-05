# Temporary overlay audit metadata — read by flake/parts/exports/overlay-audits.nix.
# Keys must match overlay identifiers in default.nix. No owner/repo#N refs (backlinks).
# Strategies: nixpkgs-version (attr+threshold), nixpkgs-issue (trackingIssues), nixpkgs-pr (trackingPRs).
# Required fields for all: strategy, description, systems. Optional: notes (coupled removals etc).
# Coupled overlays with no independent removal condition: add `# audit-exempt` inside their block in default.nix.

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
