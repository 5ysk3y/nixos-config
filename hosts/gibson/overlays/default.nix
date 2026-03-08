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

      ## Can be rm'd once https://github.com/NixOS/nixpkgs/pull/496839 is merged upstream
      libvirt = prev.libvirt.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.makeWrapper ];

        buildInputs = (old.buildInputs or [ ]) ++ [ prev.systemd ];

        postPatch = (old.postPatch or "") + ''
          substituteInPlace src/secret/virt-secret-init-encryption.service.in \
            --replace-fail /usr/bin/sh ${
              prev.lib.getExe (
                prev.writeShellApplication {
                  name = "virt-secret-init-encryption-sh";
                  runtimeInputs = [
                    prev.coreutils
                    prev.systemd
                  ];
                  text = ''exec ${prev.runtimeShell} "$@"'';
                }
              )
            }
        '';
      });
    })
  ];
}
