{ config, pkgs, lib, ... }:

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

      hyprland = prev.hyprland.overrideAttrs (finalAttrs: previousAttrs: {
        version = "0.48.1";
        src = prev.fetchFromGitHub {
          owner = "hyprwm";
          repo = "hyprland";
          fetchSubmodules = true;
          tag = "v${finalAttrs.version}";
          hash = "sha256-skuJFly6LSFfyAVy2ByNolkEwIijsTu2TxzQ9ugWarI=";
        };
      });
    })
  ];
}
