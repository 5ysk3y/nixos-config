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
            xorg.libXcursor
            xorg.libXi
            xorg.libXinerama
            xorg.libXScrnSaver
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
        mpv-unwrapped = final.mpv-unwrapped;
      };
    })
  ];
}
