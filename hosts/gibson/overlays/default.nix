{ config, pkgs, lib, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      cider = prev.cider.overrideAttrs (finalAttrs: previousAttrs: {
        version = "1.6.3";
          src = pkgs.fetchurl {
            url = "https://github.com/ciderapp/Cider/releases/download/v${finalAttrs.version}/Cider-${finalAttrs.version}.AppImage";
            sha256 = "sha256-NwoV1eeAN0u9VXWpu5mANXhmgqe8u3h7BlsREP1f/pI=";
          };
      });
    })

    (final: prev: {
      gamescope = prev.gamescope.overrideAttrs (finalAttrs: previousAttrs: {
        version = "3.14.18";
        src = prev.fetchFromGitHub {
          owner = "ValveSoftware";
          repo = "gamescope";
          rev = "refs/tags/${finalAttrs.version}";
          fetchSubmodules = true;
          hash = "sha256-XcefR0wiDHQY7wMX+LQTEntffi2RdMW8m2HNQMz035A=";
        };
      });
    })

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
  ];
}
