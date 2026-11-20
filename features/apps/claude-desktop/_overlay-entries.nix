# Claude Desktop's temporary overlay and its audit metadata. See
# hosts/personal/gibson/overlays/overlay-entries.nix for the convention.
# Applied and audited from ./default.nix (infraLib.overlaysModule and
# infra.sharedOverlayEntries).
#
# The package is read straight from an upstream PR's head branch (the
# claude-desktop-pr flake input), so each flake.lock bump picks up the PR's
# latest revision. Once NixOS/nixpkgs#587988 merges, delete this file and the
# claude-desktop-pr input, and drop this file's references from ./default.nix.
{ inputs }:
{
  permanent = _final: _prev: { };

  tracked = [
    {
      id = "claude-desktop";
      meta = {
        strategy = "nixpkgs-pr";
        description = "claude-desktop package read from its unmerged nixpkgs init PR's branch";
        evalAttr = "claude-desktop";
        systems = [ "x86_64-linux" ];
        evalHosts = [ "gibson" ];
        trackingPRs = [
          {
            repo = "NixOS/nixpkgs";
            numbers = [ 587988 ];
          }
        ];
        notes = "Coupled removal: delete this file and the claude-desktop-pr flake input, and their references in that feature's default.nix. The rest of the feature stays, on nixpkgs' pkgs.claude-desktop.";
      };
      # Adds a package rather than overriding one. callPackage on `final`, so
      # its claude-code is the claude-code-nix overlay's, not nixpkgs'.
      overlay = final: _prev: {
        claude-desktop =
          final.callPackage "${inputs.claude-desktop-pr}/pkgs/by-name/cl/claude-desktop/package.nix"
            { };
      };
    }
  ];
}
