{ config, pkgs, lib, vars, inputs, ... }:
{
  nixpkgs.overlays = [
    (final: prev: #{
      let
        # Reusable helper, adds -DCMAKE_POLICY_VERSION_MINIMUM=3.5
        withPolicy35 = drv:
          drv.overrideAttrs (old: {
            cmakeFlags = (old.cmakeFlags or []) ++ [
              (final.lib.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.5")
            ];
          });
      in
        {
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
#        };
          libmodule = withPolicy35 prev.libmodule;
      })

#    (self: super:
#    let
#      ciderAppImage = super.requireFile {
#        name = "cider-linux-x64.AppImage";
#        sha256 = "sha256-1syFQAvx4OdM2y03nP31r+YapH69ijd8XhEp4WxNxOo="; # your SRI
#        message = ''
#          Cider 2 is non-free. Download the Cider AppImage from Taproom, then place it at:
#            ~/.cache/nixpkgs/cider-linux-x64.AppImage
#          and rebuild.
#        '';
#      };
#    in {
#      cider-2 = super.cider-2.overrideAttrs (old: {
#        version = "3.1.2";
#        src = ciderAppImage;   # swap just the AppImage bytes
#      });
#    })
  ];
}
