# Single source of truth for gibson's overlays and their audit metadata.
#
# Every entry in `tracked` must be either:
#   - exempt = true   — a conscious, visible opt-out (coupled/diagnostic,
#                        no independent tracking; matches the old inline
#                        "# audit-exempt" comment convention)
#   - meta = { ... }   — real audit metadata, consumed by
#                        flake-parts/exports/overlay-audits.nix and checked
#                        by both the pre-commit hook and the weekly CI audit
#
# There is no third way for an entry to exist here without going through one
# of those two paths — this file *is* what builds nixpkgs.overlays, so an
# omitted exempt/meta isn't a missed check, it structurally has nowhere to go.
#
# Cross-referencing another tracked entry's overridden value must use
# `final.<key>`, never `prev.<key>` — `final` is always the fully-resolved
# fixed point regardless of list order; `prev` only reflects entries earlier
# in this same list.
_: {
  permanent = _final: prev: {
    steam = prev.steam.override {
      extraPkgs =
        pkgs: with pkgs; [
          libxcursor
          libXi
          libxinerama
          libxscrnsaver
          libpng
          libpulseaudio
          libvorbis
          stdenv.cc.cc.lib
          libkrb5
          keyutils
        ];
    };
  };

  tracked = [
    {
      id = "bitwarden-desktop";
      meta = {
        strategy = "nixpkgs-issue";
        description = "Fixes an issue with bitwarden holding hibernation lock, preventing the system from entering hibnerate";
        evalAttr = "bitwarden-desktop";
        systems = [ "x86_64-linux" ];
        trackingIssues = [
          {
            repo = "bitwarden/clients";
            number = 21661;
          }
        ];
        notes = "No upstream fix is proposed yet";
      };
      # Wrapped rather than overrideAttrs'd: changing the package's own
      # derivation turns every bitwarden release into a full source build,
      # where wrapping the cached package only builds this small wrapper.
      overlay = _final: prev: {
        bitwarden-desktop = prev.symlinkJoin {
          inherit (prev.bitwarden-desktop) pname version meta;
          paths = [ prev.bitwarden-desktop ];
          nativeBuildInputs = [ prev.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/bitwarden \
                --set SECURE_KEY_CONTAINER_BACKEND keyctl
          '';
        };
      };
    }
  ];
}
