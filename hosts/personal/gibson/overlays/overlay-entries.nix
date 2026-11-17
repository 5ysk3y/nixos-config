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
        description = "Fixes an issue with bitwarden holding hibernation lock, preventing the system from entering hibernation";
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

    {
      id = "linux-zen-workqueue-null-deref";
      meta = {
        strategy = "nixpkgs-pr";
        description = "Patch linux_zen 7.3.4-zen1's mis-merged process_one_work(), which NULL-derefs on BH workers and panics gibson at boot";
        evalAttr = "linuxPackages_zen.kernel";
        systems = [ "x86_64-linux" ];
        trackingPRs = [
          {
            repo = "NixOS/nixpkgs";
            # linux_zen: 7.3.4-zen1 -> 7.3.4-zen2 (ships zen-kernel d0c3b48,
            # fixing zen-kernel/zen-kernel#425).
            numbers = [ 586820 ];
          }
        ];
        notes = "kernel.version reads 7.3.4 for both zen1 and zen2; check modDirVersion instead. Once landed, `nix eval .#nixosConfigurations.gibson.config.boot.kernelPackages.kernel.modDirVersion` should report 7.3.4-zen2 or later. Once upstream merges remove the overlay and the associated patch file";
      };
      # Mirrors how nixos/modules/system/boot/kernel.nix applies
      # boot.kernelPatches (extend + kernel.override), but as an overlay so
      # it's audited. Rebuilds the kernel and its out-of-tree modules
      # (nvidia-open) locally rather than substituting from cache.nixos.org.
      overlay = _final: prev: {
        linuxPackages_zen = prev.linuxPackages_zen.extend (
          _kfinal: kprev: {
            kernel =
              if kprev.kernel.modDirVersion == "7.3.4-zen1" then
                kprev.kernel.override (orig: {
                  kernelPatches = (orig.kernelPatches or [ ]) ++ [
                    {
                      name = "zen-workqueue-bh-null-deref";
                      patch = ./patches/zen-workqueue-bh-null-deref.patch;
                    }
                  ];
                })
              else
                prev.lib.warn "linux-zen-workqueue-null-deref: linux_zen is now ${kprev.kernel.modDirVersion}, overlay is inert; remove it" kprev.kernel;
          }
        );
      };
    }
  ];
}
