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
        version = "3.15.2";
        buildInputs = previousAttrs.buildInputs ++ [ pkgs.lcms2 ];
        src = prev.fetchFromGitHub {
          owner = "ValveSoftware";
          repo = "gamescope";
          rev = "refs/tags/${finalAttrs.version}";
          fetchSubmodules = true;
          hash = "sha256-g6H68dYMmpQYlwhZ6b84yY/qbAP18iNrmYOWf9rL5gc=";
        };
      });
    })

    (final: prev: {
      xdg-desktop-portal-hyprland = prev.xdg-desktop-portal-hyprland.overrideAttrs (finalAttrs: previousAttrs: {
        patches = [
          (pkgs.fetchpatch {
            url = "https://github.com/hyprwm/xdg-desktop-portal-hyprland/commit/5555f467f68ce7cdf1060991c24263073b95e9da.patch";
            hash = "sha256-yNkg7GCXDPJdsE7M6J98YylnRxQWpcM5N3olix7Oc1A=";
          })

          (pkgs.fetchpatch {
            url = "https://github.com/hyprwm/xdg-desktop-portal-hyprland/commit/0dd9af698b9386bcf25d3ea9f5017eca721831c1.patch";
            hash = "sha256-Y6eWASHoMXVN2rYJ1rs0jy2qP81/qbHsZU+6b7XNBBg=";
          })

          (pkgs.fetchpatch {
            url = "https://github.com/hyprwm/xdg-desktop-portal-hyprland/commit/2425e8f541525fa7409d9f26a8ffaf92a3767251.patch";
            hash = "sha256-6dCg/U/SIjtvo07Z3tn0Hn8Xwx72nwVz6Q2cFnObonU=";
          })
        ];

        depsBuildBuild = [
          pkgs.pkg-config
        ];
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
