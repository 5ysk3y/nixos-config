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
        strategy = "nixpkgs-version";
        description = "Build qutebrowser against the pre-Qt-6.12 python3/qt6Packages set; pyqt6 6.11.0 + Qt 6.12 fails to import on darwin (QPyTableRange symbol)";
        evalAttr = "qutebrowser";
        attr = "python3Packages.pyqt6.version";
        systems = [ "aarch64-darwin" ];
        threshold = "6.12.0";
        notes = "This is dependant on pyqt6 reaching v6.12.0 upstream — confirm with `nix build .#darwinConfigurations.macbook.pkgs.python3Packages.pyqt6` before removing. Also remove the nixpkgs-qt-darwin flake input.";
      };
      # .override (not overrideAttrs) swaps the Qt/Python stack the package is
      # called with, so this composes with the shared qutebrowser overlay's
      # overrideAttrs (FIDO2 src) whichever order the two lists land in.
      # Whole stack from one rev on purpose: mixing a Qt 6.11 pyqt6 with Qt 6.12
      # qtwebengine in one closure is an ABI mismatch waiting to happen.
      overlay = _final: prev: {
        qutebrowser = prev.qutebrowser.override {
          inherit (inputs.nixpkgs-qt-darwin.legacyPackages.${prev.stdenv.hostPlatform.system})
            python3
            qt6Packages
            ;
        };
      };
    }
  ];
}
