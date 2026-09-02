# Single source of truth for the system-wide (cross-host) overlays and their
# audit metadata. See hosts/gibson/overlays/overlay-entries.nix for the full
# convention explanation. Kept underscore-prefixed like the other files in
# this directory, per the dendritic convention of excluding it from
# import-tree's flake-parts module discovery.
{
  inputs ? null,
  pkgs ? null,
  ...
}:
{
  permanent = _final: _prev: { };

  tracked = [
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
        qutebrowser = prev.qutebrowser.overrideAttrs (old: {
          version = "unstable-2026-08-04";
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
