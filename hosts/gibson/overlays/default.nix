{ config, pkgs, lib, vars, ... }:

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

    (self: super: {
      cider-2 = super.cider-2.overrideAttrs (old: {
        src = pkgs.fetchurl {
          url = "file://${vars.syncthingPath}/Files/nix/Cider/cider-linux-x64.AppImage";
          sha256 = "0qjhsssccxiq92zs04zhi53bkaf2qwfq7ryic1w9sha59ffyxqbf";
        };
      });
    })
  ];
}
