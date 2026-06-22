{
  inputs,
  pkgs,
  ...
}:

{
  nixpkgs.overlays = [
    # claude-code-nix: must be applied at system level — nixpkgs.overlays set
    # inside HM modules has no effect when useGlobalPkgs = true.
    inputs.claude-code-nix.overlays.default

    (final: prev: {
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

      mpv-unwrapped = prev.mpv-unwrapped.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          ./patches/mpv-fence-leak.patch
        ];
      });

      mpv = prev.mpv.override {
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

      # TODO: Monitor new hyprland package releases
      # This is currently propagating upstream through Hydra into nixos-unstable
      hyprland = prev.hyprland.overrideAttrs (old: {
        version = "0.55.4";
        src = old.src.override {
          tag = "v0.55.4";
          hash = "sha256-IuT0HnOr/0rAw+GXr+OwWx89FjA4Og1FqP7vywEwRJM=";
        };
      });
      xdg-desktop-portal-hyprland = prev.xdg-desktop-portal-hyprland.override {

        inherit (final) hyprland; # uses the overridden version above
      };
    })

    inputs.self.overlays.default
  ];
}
