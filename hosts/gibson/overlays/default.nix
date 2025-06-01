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
      cider-2 = super.cider-2.overrideAttrs (_: {
        src = pkgs.requireFile {
          name = "cider-linux-x64.AppImage";
          url = "https://cidercollective.itch.io/cider";
          sha256 = "5d506132048d240613469c79186ae8b5e78ec7400f233b8709b7fe908353d9e5";
        };
      });
    })
  ];
}
