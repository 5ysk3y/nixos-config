# Single source of truth for the system-wide (cross-host) overlays and their
# audit metadata. See hosts/personal/gibson/overlays/overlay-entries.nix for the full
# convention explanation. Kept underscore-prefixed like the other files in
# this directory, per the dendritic convention of excluding it from
# import-tree's flake-parts module discovery.
#
# An entry may also carry `permittedInsecurePackages`, which ./_module.nix
# merges into nixpkgs.config, so a permit is removed together with the entry
# that justifies it.
_:
let
  # Shared by the FIDO2 overlay and the insecure-package permit below, so a
  # bump of the fork moves both and the permit can't outlive the exact build
  # it was granted for.
  qutebrowserVersion = "unstable-2026-08-04";
in
{
  permanent = _final: _prev: { };

  tracked = [
    {
      id = "qutebrowser-emudhra-permit";
      meta = {
        strategy = "nixpkgs-pr";
        evalAttr = "qutebrowser";
        description = "Permit qutebrowser despite nixpkgs marking it insecure: QtWebEngine before 6.140.0 trusts the compromised eMudhra intermediates (CVE-2026-111943)";
        systems = [
          "aarch64-darwin"
          "x86_64-linux"
        ];
        evalHosts = [
          "gibson"
          "macbook"
        ];
        trackingPRs = [
          {
            repo = "NixOS/nixpkgs";
            # qt6.qtwebengine 6.140.0-rc -> 6.140.0: its Chromium adds the
            # eight compromised eMudhra SPKIs to the built-in blocklist,
            # which the verifier applies on Linux and macOS alike. Append the
            # PR that drops qutebrowser's knownVulnerabilities once one exists.
            numbers = [ 587672 ];
          }
        ];
        notes = "Landed = the eMudhra fix is in the locked nixpkgs. Confirm every case on https://emudhra.we-have-a-problem.com/ is rejected on each host. nixpkgs still flags qutebrowser after the fix (no PR to drop it as of 2026-11-14): keep this entry until the locked qutebrowser package.nix has no knownVulnerabilities, then remove it.";
      };
      permittedInsecurePackages = [ "qutebrowser-${qutebrowserVersion}" ];
      overlay = _final: _prev: { };
    }

    {
      id = "qutebrowser";
      meta = {
        strategy = "nixpkgs-pr";
        evalAttr = "qutebrowser";
        description = "Implements FIDO2 support awaiting upstream merging";
        systems = [
          "aarch64-darwin"
          "x86_64-linux"
        ];
        evalHosts = [
          "gibson"
          "macbook"
        ];
        trackingPRs = [
          {
            repo = "qutebrowser/qutebrowser";
            numbers = [ 8642 ];
          }
        ];
      };
      # Unstable qutebrowser build with unmerged FIDO2 support.
      # Remove once upstream merges https://github.com/qutebrowser/qutebrowser/pull/8642
      overlay = final: prev: {
        qutebrowser = prev.qutebrowser.overrideAttrs (_old: {
          version = qutebrowserVersion;
          src = final.fetchFromGitHub {
            owner = "coderkun";
            repo = "qutebrowser";
            rev = "4c0fc4fdf6721028957cddd3075d8df09e170951";
            hash = "sha256-BVCbCSh80J7UQm5G2Ub1Ah4yzm58PYiNHR/mbSynDeE=";
          };
        });
      };
    }
  ];
}
