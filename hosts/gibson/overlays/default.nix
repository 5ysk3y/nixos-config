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

    (
      final: prev:
      let
        # TODO: hibernate/hyprlock black-screen bisect — remove once root cause confirmed/fixed upstream
        # audit-exempt (diagnostic only, no upstream issue filed yet)
        oldNixpkgs =
          import
            (prev.fetchFromGitHub {
              owner = "NixOS";
              repo = "nixpkgs";
              rev = "a47c123a609287a012dfc44d281de2dd4ed13394";
              hash = "sha256-IpX7tmVJi9seHg5M4Wuexy78bQDlbntVk1HcT9kFts4=";
            })
            {
              inherit (prev) system;
              config.allowUnfree = true;
            };
      in
      {
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

        # TODO: Monitor new bitwarden package releases
        # Upstream issue has no permanent fix yet:
        # https://github.com/bitwarden/clients/issues/21661
        bitwarden-desktop = prev.bitwarden-desktop.overrideAttrs (old: {
          postFixup = (old.postFixup or "") + ''
            wrapProgram $out/bin/bitwarden \
              --set SECURE_KEY_CONTAINER_BACKEND keyctl
          '';
        });

        # ── Temporary overlays ─────────────────────────────────────────
        # TODO: hibernate/hyprlock black-screen bisect — remove once root cause confirmed/fixed upstream
        # audit-exempt (diagnostic only, no upstream issue filed yet)
        inherit (oldNixpkgs)
          hyprland
          hyprlock
          hyprutils
          aquamarine
          ;
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
      }
    )
  ];
}
