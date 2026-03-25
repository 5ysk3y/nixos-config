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

      # Temporary workaround for less 691 xterm-kitty pager regression.
      # Remove once nixpkgs includes less >= 692 everywhere we build.
      # https://github.com/NixOS/nixpkgs/pull/490763
      less = prev.less.overrideAttrs (_: rec {
        version = "692";
        src = prev.fetchurl {
          url = "https://www.greenwoodsoftware.com/less/less-${version}.tar.gz";
          hash = "sha256-YTAPYDeY7PHXeGVweJ8P8/WhrPB1pvufdWg30WbjfRQ=";
        };
      });
    })
  ];
}
