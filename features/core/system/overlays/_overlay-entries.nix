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
  qutebrowserVersion = "unstable-2026-11-19";
in
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
      # Remove once upstream merges https://github.com/qutebrowser/qutebrowser/pull/8642,
      # checking first that the merged code no longer needs
      # ./patches/qutebrowser-webauth-states.patch.
      overlay = final: prev: {
        qutebrowser = prev.qutebrowser.overrideAttrs (old: {
          version = qutebrowserVersion;
          # Two fixes to the fork's WebAuth state handler, as of ab64eb1:
          # - the CollectPin branch starts a new `if` chain, so NotStarted
          #   and SelectAccount fall through it to Unreachable
          # - it names WebAuthUxState.Discovery, which PyQt6-WebEngine 6.11
          #   lacks, so reaching that branch raises; matched by value
          patches = (old.patches or [ ]) ++ [ ./patches/qutebrowser-webauth-states.patch ];
          src = final.fetchFromGitHub {
            owner = "coderkun";
            repo = "qutebrowser";
            rev = "ab64eb17678305e5234a7cc0e18e1dff8508cfa3";
            hash = "sha256-51bzrrpUwoMeVCumJkCUIgBuoIkQxIj6cifcUP8KJqU=";
          };
        });
      };
    }
  ];
}
