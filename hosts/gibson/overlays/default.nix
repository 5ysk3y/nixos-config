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
    })

    (self: super: {
        htop-vim = super.stdenv.mkDerivation rec {
        pname = "htop-vim";
        version = "unstable-2023-02-16";

            # Define support flags
        sensorsSupport = super.stdenv.hostPlatform.isLinux;
        systemdSupport = super.stdenv.hostPlatform.isLinux;

        src = super.fetchFromGitHub {
          owner = "htop-dev";
          repo = "htop";
          rev = "0dac8e7d38ec3aeae901a987717b5177986197e4";
          hash = "sha256-ZfdBAlnjoy8g6xwrR/i2+dGldMOfLlX6DRlNqB8pkGM=";
        };

        patches = [
          # See https://github.com/htop-dev/htop/pull/1412
          # Remove when updating to 3.4.0
          (super.fetchpatch {
            name = "htop-resolve-configuration-path.patch";
            url = "https://github.com/htop-dev/htop/commit/0dac8e7d38ec3aeae901a987717b5177986197e4.patch";
            sha256 = "sha256-Er1d/yV1fioYfEmXNlLO5ayAyXkyy+IaGSx1KWXvlv0=";
          })
        ];

        nativeBuildInputs = [ super.autoreconfHook ]
          ++ lib.optional super.stdenv.hostPlatform.isLinux super.pkg-config;

        buildInputs = [ super.ncurses ]
          ++ lib.optionals super.stdenv.hostPlatform.isDarwin [ super.darwin.IOKit ]
          ++ lib.optionals super.stdenv.hostPlatform.isLinux [
            super.libcap
            super.libnl
          ]
          ++ lib.optional sensorsSupport super.lm_sensors
          ++ lib.optional systemdSupport super.systemd;

        configureFlags = [
          "--enable-unicode"
          "--sysconfdir=/etc"
        ]
          ++ lib.optionals super.stdenv.hostPlatform.isLinux [
            "--enable-affinity"
            "--enable-capabilities"
            "--enable-delayacct"
          ]
          ++ lib.optional sensorsSupport "--enable-sensors";

        postFixup = let
          optionalPatch = pred: so: lib.optionalString pred ''
            patchelf --add-needed ${so} $out/bin/htop
          '';
        in lib.optionalString (!super.stdenv.hostPlatform.isStatic) ''
          ${optionalPatch sensorsSupport "${lib.getLib super.lm_sensors}/lib/libsensors.so"}
          ${optionalPatch systemdSupport "${super.systemd}/lib/libsystemd.so"}
        '';

        meta = with lib; {
          description = "Interactive process viewer";
          homepage = "https://htop.dev";
          license = licenses.gpl2Only;
          platforms = platforms.all;
          maintainers = with maintainers; [ super.thiagokokada ];
          changelog = "https://github.com/htop-dev/htop/blob/${version}/ChangeLog";
          mainProgram = "htop";
        };
      };

      pwvucontrol = super.callPackage ./pwvucontrol/default.nix {};
    })
  ];
}
