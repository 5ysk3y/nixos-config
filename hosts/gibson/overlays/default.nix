{
  inputs,
  pkgs,
  ...
}:

{
  nixpkgs.overlays = [
    # claude-code-nix: must be applied at system level — nixpkgs.overlays set
    # inside HM modules has no effect when useGlobalPkgs = true.
    inputs.claude-code-nix.overlays.default

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

      # TODO(upstream): remove once upstream has a fix
      # https://github.com/NixOS/nixpkgs/issues/513245 - Build failure: lutris-free
      # https://github.com/NixOS/nixpkgs/issues/514113 - pkgsi686Linux.openldap: test checks won't let it compile on x86_64
      # Context: Prevents build test failures in OpenLDAP as required by Lutris
      lutris = prev.lutris.override {
        # Intercept buildFHSEnv to modify target packages
        buildFHSEnv =
          args:
          pkgs.buildFHSEnv (
            args
            // {
              multiPkgs =
                envPkgs:
                let
                  # Fetch original package list
                  originalPkgs = args.multiPkgs envPkgs;

                  # Disable tests for openldap
                  customLdap = envPkgs.openldap.overrideAttrs (_: {
                    doCheck = false;
                  });
                in
                # Replace broken openldap with the custom one
                builtins.filter (p: (p.pname or "") != "openldap") originalPkgs ++ [ customLdap ];
            }
          );
      };
    })
  ];
}
