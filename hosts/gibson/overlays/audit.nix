# Temporary overlay audit metadata — read by flake/parts/exports/overlay-audits.nix.
# Keys must match overlay identifiers in default.nix. No owner/repo#N refs (backlinks).
# Strategies: nixpkgs-version (attr+threshold), nixpkgs-issue (trackingIssues), nixpkgs-pr (trackingPRs).
# Required fields for all: strategy, description, systems. Optional: notes (coupled removals etc).
# Coupled overlays with no independent removal condition: add `# audit-exempt` inside their block in default.nix.

{
  bitwarden-desktop = {
    description = "Override electron_39 with electron_39-bin to unblock bitwarden-desktop build";
    notes = "Also remove permittedInsecurePackages entry from hosts/gibson/system.nix.";
    strategy = "nixpkgs-issue";
    systems = [ "x86_64-linux" ];
    trackingIssues = [
      {
        number = 526914;
        repo = "NixOS/nixpkgs";
      }
    ];
  };

  mpv-unwrapped = {
    description = "Backport fence-sync fix milestoned for mpv 0.42.0";
    notes = "mpv override is a coupled removal — remove both blocks together.";
    strategy = "nixpkgs-version";
    systems = [ "x86_64-linux" ];
    threshold = "0.42.0";
  };

  waybar = {
    description = "Pin waybar to git-0594574 pending next tagged release";
    notes = "Also remove waybar-patched flake input from flake.nix. Release cadence has been strictly minor bumps since 0.11.0.";
    strategy = "nixpkgs-version";
    systems = [ "x86_64-linux" ];
    threshold = "0.16.0";
  };

}
