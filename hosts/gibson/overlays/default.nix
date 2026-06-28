# Place overlays in the relevant section based on comment headers
# Ensure all major packages have accompanying entries in ./audit.nix
# Use  "# audit-exempt" comment to items that are coupled with tracked/audited overlays
{
  inputs,
  ...
}:

{
  nixpkgs.overlays = [
    # claude-code-nix: must be applied at system level — nixpkgs.overlays set
    # inside HM modules has no effect when useGlobalPkgs = true.
    inputs.claude-code-nix.overlays.default
    inputs.self.overlays.default

    (final: prev: {
      # ── Permanent overlays ─────────────────────────────────────────
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

      # ── Temporary overlays ─────────────────────────────────────────
      # TODO: Monitor new mpv package releases
      # Associated PR is merged; requires a new release.
      mpv-unwrapped = prev.mpv-unwrapped.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          ./patches/mpv-fence-leak.patch
        ];
      });

      mpv = prev.mpv.override {
        # audit-exempt
        inherit (final) mpv-unwrapped;
      };

      # upstream nixpkgs issue - remove when bitwarden-desktop bumps electron
      # TODO: Monitor this for upstream: https://github.com/NixOS/nixpkgs/issues/526914
      # Also remove permittedInsecurePackages from hosts/gibson/system.nix
      bitwarden-desktop = prev.bitwarden-desktop.override {
        electron_39 = final.electron_39-bin;
      };

      # TODO: Monitor new waybar package releases
      # Associated PR is merged; requires a new release.
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
    })

  ];
}
