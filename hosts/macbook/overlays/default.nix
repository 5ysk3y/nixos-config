{
  inputs,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  qtPinnedPkgs = import inputs.qtwebengine-fix {
    inherit system;
    config.allowUnfree = true;
  };
in
{
  nixpkgs.overlays = [
    (final: prev: {
      # Temporary qtwebengine Darwin build fix.
      # Remove once upstream nixpkgs includes https://github.com/NixOS/nixpkgs/pull/515997
      # Changes to these patches will require a rebuild.
      qt6 = qtPinnedPkgs.qt6.overrideScope (
        _qtFinal: qtPrev: {
          qtwebengine = qtPinnedPkgs.qt6.qtwebengine.overrideAttrs (old: {
            patches =
              (old.patches or [ ])
              ++ final.lib.optionals final.stdenv.hostPlatform.isDarwin [
                (final.fetchpatch {
                  url = "https://raw.githubusercontent.com/NixOS/nixpkgs/2097933ced42bd2235a58b5483f38d738ca6d7b0/pkgs/development/libraries/qt-6/modules/qtwebengine/clang-base-path-from-cmake-compiler.patch";
                  hash = "sha256-Z0vcxZeUlTv1YaWlxWT2r61pi1X8Q3kCTRoahNfa7Jc=";
                })

                (final.fetchpatch {
                  url = "https://raw.githubusercontent.com/NixOS/nixpkgs/2097933ced42bd2235a58b5483f38d738ca6d7b0/pkgs/development/libraries/qt-6/modules/qtwebengine/lflags-remove-strip-darwin-isysroot.patch";
                  hash = "sha256-ie3MJmDfJ2Af1ZtkOYGkUmBanUe/kqv1+uxIQmzzv6I=";
                })
              ];

            cmakeFlags = map (
              flag:
              if final.stdenv.hostPlatform.isDarwin && flag == "-DCMAKE_OSX_DEPLOYMENT_TARGET=11.0" then
                "-DCMAKE_OSX_DEPLOYMENT_TARGET=12.0"
              else
                flag
            ) (old.cmakeFlags or [ ]);
          });
        }
      );
    })
  ];
}
