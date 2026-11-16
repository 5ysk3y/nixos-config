# Claude Desktop's temporary overlay and its audit metadata. See
# hosts/personal/gibson/overlays/overlay-entries.nix for the convention.
# Applied by ./_nixos.nix, audited via infra.sharedOverlayEntries (./default.nix).
#
# Once NixOS/nixpkgs#587988 merges, delete this file and ./_package.nix, and
# drop their references from ./default.nix and ./_nixos.nix.
_: {
  permanent = _final: _prev: { };

  tracked = [
    {
      id = "claude-desktop";
      meta = {
        strategy = "nixpkgs-pr";
        description = "Vendored claude-desktop package from its unmerged nixpkgs init PR";
        evalAttr = "claude-desktop";
        systems = [ "x86_64-linux" ];
        evalHosts = [ "gibson" ];
        trackingPRs = [
          {
            repo = "NixOS/nixpkgs";
            numbers = [ 587988 ];
          }
        ];
        notes = "Coupled removal: delete features/apps/claude-desktop/_package.nix and this file, and their references in that feature's default.nix and _nixos.nix. The rest of the feature stays, on nixpkgs' pkgs.claude-desktop.";
      };
      # Adds a package rather than overriding one. callPackage on `final`, so
      # its claude-code is the claude-code-nix overlay's, not nixpkgs'.
      overlay = final: _prev: {
        claude-desktop = final.callPackage ./_package.nix { };
      };
    }
  ];
}
