# Single source of truth for gibson's overlays and their audit metadata.
#
# Every entry in `tracked` must be either:
#   - exempt = true   — a conscious, visible opt-out (coupled/diagnostic,
#                        no independent tracking; matches the old inline
#                        "# audit-exempt" comment convention)
#   - meta = { ... }   — real audit metadata, consumed by
#                        flake/parts/exports/overlay-audits.nix and checked
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
  permanent = final: prev: {
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
      id = "hyprland-blackscreen-bisect";
      # TODO: hibernate/hyprlock black-screen bisect — remove once root cause confirmed/fixed upstream
      exempt = true; # diagnostic only, no upstream issue filed yet
      overlay =
        final: prev:
        let
          oldNixpkgs =
            import
              (prev.fetchFromGitHub {
                owner = "NixOS";
                repo = "nixpkgs";
                rev = "a47c123a609287a012dfc44d281de2dd4ed13394";
                hash = "sha256-IpX7tmVJi9seHg5M4Wuexy78bQDlbntVk1HcT9kFts4=";
              })
              {
                inherit (prev.stdenv.hostPlatform) system;
                config.allowUnfree = true;
              };
        in
        {
          inherit (oldNixpkgs)
            hyprland
            hyprlock
            hyprutils
            aquamarine
            ;
        };
    }

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
      overlay = final: prev: {
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
      overlay = final: prev: {
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
      overlay = final: prev: {
        bitwarden-desktop = prev.bitwarden-desktop.overrideAttrs (old: {
          postFixup = (old.postFixup or "") + ''
            wrapProgram $out/bin/bitwarden \
              --set SECURE_KEY_CONTAINER_BACKEND keyctl
          '';
        });
      };
    }
  ];
}
