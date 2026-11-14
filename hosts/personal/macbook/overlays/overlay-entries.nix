# Single source of truth for macbook's overlays and their audit metadata.
# See hosts/personal/gibson/overlays/overlay-entries.nix for the full convention
# explanation (exempt vs meta, final vs prev discipline).
{ inputs, ... }:
{
  permanent = _final: _prev: { };
  tracked = [
    {
      id = "qutebrowser-qt-pin";
      meta = {
        strategy = "nixpkgs-pr";
        description = "Build qutebrowser against QtWebEngine 6.140.0 from nixpkgs master, whose Chromium blocklists the compromised eMudhra keys, ahead of it reaching nixos-unstable";
        evalAttr = "qutebrowser";
        systems = [ "aarch64-darwin" ];
        trackingPRs = [
          {
            repo = "NixOS/nixpkgs";
            # 584657: pyqt6 imports against Qt 6.12 on darwin (the original
            # reason for this pin). 587672: qtwebengine 6.140.0-rc -> 6.140.0.
            numbers = [
              584657
              587672
            ];
          }
        ];
        notes = "Coupled removal: also remove the nixpkgs-qt-darwin flake input. Once removed, confirm `nix eval .#darwinConfigurations.macbook.pkgs.qt6Packages.qtwebengine.version` reports 6.140.0 (not 6.140.0-rc), and launch qutebrowser on the macbook.";
      };
      # .override (not overrideAttrs) swaps the Qt/Python stack the package is
      # called with, so this composes with the shared FIDO2 overlay's
      # overrideAttrs whichever order the lists land in. The whole stack comes
      # from one rev on purpose, to avoid mixing Qt ABIs in one closure. It is
      # imported with this host's config rather than via legacyPackages: the
      # pinned python3's buildPythonApplication runs qutebrowser's meta check,
      # and legacyPackages would apply the default config, dropping any
      # permittedInsecurePackages entry.
      overlay =
        _final: prev:
        let
          pinned = import inputs.nixpkgs-qt-darwin {
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
  ];
}
