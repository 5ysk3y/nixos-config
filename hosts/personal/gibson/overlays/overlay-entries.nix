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
{ inputs }:
{
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
      id = "mpv-unwrapped";
      meta = {
        strategy = "nixpkgs-version";
        description = "Backport fence-sync fix milestoned for mpv 0.42.0";
        evalAttr = "mpv-unwrapped";
        systems = [ "x86_64-linux" ];
        threshold = "0.42.0";
        notes = "mpv override is a coupled removal — remove both entries together.";
      };
      overlay = _final: prev: {
        mpv-unwrapped = prev.mpv-unwrapped.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            ./patches/mpv-fence-leak.patch
          ];
        });
      };
    }

    {
      id = "mpv-coupled";
      exempt = true; # coupled to mpv-unwrapped above, no independent tracking
      overlay = final: prev: {
        mpv = prev.mpv.override {
          inherit (final) mpv-unwrapped;
        };
      };
    }

    {
      id = "waybar";
      meta = {
        strategy = "nixpkgs-version";
        description = "Pin waybar to git-0594574 pending next tagged release";
        evalAttr = "waybar";
        systems = [ "x86_64-linux" ];
        threshold = "0.16.0";
        notes = "Also remove waybar-patched flake input from flake.nix. Release cadence has been strictly minor bumps since 0.11.0.";
      };
      overlay = _final: prev: {
        waybar = prev.waybar.overrideAttrs (old: {
          src = inputs.waybar-patched;
          version = "git-0594574";
          mesonFlags = (builtins.filter (f: f != "-Dcava=enabled") (old.mesonFlags or [ ])) ++ [
            "-Dcava=disabled"
          ];
          doInstallCheck = false;
          doCheck = false;
          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.catch2_3 ];
        });
      };
    }

    {
      id = "xpad-noone";
      meta = {
        strategy = "nixpkgs-pr";
        description = "Backport xpad-noone modules_install fix (missing .ko.cer breaks linux-zen modules build)";
        evalAttr = "linuxPackages_zen.xpad-noone";
        systems = [ "x86_64-linux" ];
        trackingPRs = [
          {
            repo = "NixOS/nixpkgs";
            numbers = [ 576469 ];
          }
        ];
        notes = "Pulled in via hardware.xone (features/gaming) -> hardware.xpad-noone. Override is scoped to linuxPackages_zen only; widen it if boot.kernelPackages changes.";
      };
      # Mirrors the functional part of nixpkgs PR 576469: build-system
      # modules_install instead of a hand-rolled `install *.ko`, so the
      # .ko.cer the module aggregation step requires actually gets created.
      # installPhase = null drops the old override so stdenv's default
      # installPhase (make $installFlags $installTargets) runs instead.
      overlay = _final: prev: {
        linuxPackages_zen = prev.linuxPackages_zen.extend (
          lfinal: lprev: {
            xpad-noone = lprev.xpad-noone.overrideAttrs (
              old:
              let
                kbuild = "${lfinal.kernel.dev}/lib/modules/${lfinal.kernel.modDirVersion}/build";
              in
              {
                makeFlags = (old.makeFlags or [ ]) ++ [
                  "KERNEL_SRC=${kbuild}"
                  "INSTALL_MOD_PATH=${placeholder "out"}"
                  "INSTALL_MOD_DIR=kernel/drivers/xpad-noone"
                ];
                installPhase = null;
                installTargets = [ "modules_install" ];
                installFlags = [
                  "-C"
                  kbuild
                  "M=$(PWD)"
                ];
              }
            );
          }
        );
      };
    }

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
