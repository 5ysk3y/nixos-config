# Single source of truth for the system-wide (cross-host) overlays and their
# audit metadata. See hosts/personal/gibson/overlays/overlay-entries.nix for the full
# convention explanation. Kept underscore-prefixed like the other files in
# this directory, per the dendritic convention of excluding it from
# import-tree's flake-parts module discovery.
#
# An entry may also carry `permittedInsecurePackages`, which ./_module.nix
# merges into nixpkgs.config, so a permit is removed together with the entry
# that justifies it.
{ inputs, ... }:
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
      id = "qutebrowser-qtwebengine";
      meta = {
        strategy = "nixpkgs-pr";
        evalAttr = "qutebrowser";
        description = "Build qutebrowser against QtWebEngine 6.140.0 from nixpkgs master, whose Chromium blocklists the compromised eMudhra keys, ahead of it reaching nixos-unstable";
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
            # qt6.qtwebengine 6.140.0-rc -> 6.140.0. It merged to master after
            # the darwin pyqt6 fix (NixOS/nixpkgs#584657), so once it's in the
            # locked nixpkgs, that fix is too.
            numbers = [ 587672 ];
          }
        ];
        notes = "Coupled removal: also remove the nixpkgs-qtwebengine flake input. Once removed, confirm `nix eval .#nixosConfigurations.gibson.pkgs.qt6Packages.qtwebengine.version` and `nix eval .#darwinConfigurations.macbook.pkgs.qt6Packages.qtwebengine.version` both report 6.140.0 (not 6.140.0-rc), and launch qutebrowser on the macbook.";
      };
      # .override (not overrideAttrs) swaps the Qt/Python stack the package is
      # called with, so this composes with the FIDO2 overlay's overrideAttrs
      # whichever order the entries apply in. The whole stack comes from one
      # rev on purpose, to avoid mixing Qt ABIs in one closure. It is imported
      # with the host's config rather than via legacyPackages: the pinned
      # python3's buildPythonApplication runs qutebrowser's meta check, and
      # legacyPackages would apply the default config, dropping the permit
      # below.
      overlay =
        _final: prev:
        let
          pinned = import inputs.nixpkgs-qtwebengine {
            inherit (prev.stdenv.hostPlatform) system;
            inherit (prev) config;
          };
        in
        {
          qutebrowser = prev.qutebrowser.override {
            inherit (pinned) python3 qt6Packages;
          };
        };
    }

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
