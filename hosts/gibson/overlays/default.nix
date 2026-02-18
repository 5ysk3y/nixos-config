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
      # via PR #487740
      waybar =
        let
          libcavaVersion = "0.10.7-beta";
          libcavaSrc = prev.fetchFromGitHub {
            owner = "LukashonakV";
            repo = "cava";
            tag = "v${libcavaVersion}";
            hash = "sha256-IX1B375gTwVDRjpRfwKGuzTAZOV2pgDWzUd4bW2cTDU=";
          };
          stageLibcava = ''
            pushd "$sourceRoot"
            cp -R --no-preserve=mode,ownership ${libcavaSrc} subprojects/cava-${libcavaVersion}
            patchShebangs .
            popd
          '';
        in
        prev.waybar.overrideAttrs (old: rec {
          version = "0.15.0";

          src = prev.fetchFromGitHub {
            owner = "Alexays";
            repo = "Waybar";
            tag = version;
            hash = "sha256-49ZKgK96a9uFip+svOdnw397xcEjiftXzd9gyv1H3sU=";
          };

          postUnpack =
            let
              oldPost =
                if old ? postUnpack then
                  (if builtins.isList old.postUnpack then old.postUnpack else [ old.postUnpack ])
                else
                  [ ];
            in
            oldPost ++ [ stageLibcava ];
        });
    })
  ];
}
