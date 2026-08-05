# Temporary overlay audit metadata — read by flake/parts/exports/overlay-audits.nix.
# Keys must match overlay identifiers in default.nix. No owner/repo#N refs (backlinks).
# Strategies: nixpkgs-version (attr+threshold), nixpkgs-issue (trackingIssues), nixpkgs-pr (trackingPRs).
# Required fields for all: strategy, description, systems. Optional: notes (coupled removals etc).
# Coupled overlays with no independent removal condition: add `# audit-exempt` inside their block in default.nix.

{
  qutebrowser = {
    strategy = "nixpkgs-pr";
    description = "Implements FIDO2 support awaiting upstream merging";
    systems = [
      "aarch64-darwin"
      "x86_64-linux"
    ];
    trackingPRs = [
      {
        repo = "qutebrowser/qutebrowser";
        number = 8642;
      }
    ];
  };
}
