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

      heroic = prev.heroic.override {
        extraPkgs = pkgs: with pkgs; [
          gamescope
          gamemode
        ];
      };
    })

    (self: super: {
      cider-2 = super.cider-2.overrideAttrs (old: {
        src = "${vars.syncthingPath}/Files/nix/Cider/cider-linux-x64.AppImage";
      });
    })
  ];
}
