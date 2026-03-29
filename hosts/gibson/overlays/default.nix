{
  config,
  pkgs,
  lib,
  vars,
  inputs,
  ...
}:
{
  nixpkgs.overlays = [
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
    })
  ];
}
