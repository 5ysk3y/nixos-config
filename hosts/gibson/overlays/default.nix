{ config, pkgs, lib, vars, inputs, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      steam = prev.steam.override {
        extraPkgs = pkgs: with pkgs; [
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
    })

    (self: super:
      let
        ciderAppImage = inputs.cider-2-image;
      in
    {
      cider-2 = super.cider-2.overrideAttrs (old: {
        src = ciderAppImage;
        preConfigure = ''
          if [ ! -e ${toString ciderAppImage} ]; then
            echo "Missing Cider AppImage at: ${toString ciderAppImage}"
            exit 1
          fi
        '' + (old.preConfigure or "");
      });
    })
  ];
}
