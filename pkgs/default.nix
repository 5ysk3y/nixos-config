{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages =
        lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          game-cleanup = pkgs.callPackage ./game-cleanup { };
          xivlauncher-rb = pkgs.callPackage ./nixos-xivlauncher-rb { };
        }
        // rec {
          nvd-summary = pkgs.callPackage ./nvd-summary { };
          nix-build-system = pkgs.callPackage ./nix-build-system { inherit nvd-summary; };
        };
    };

  flake.overlays.default = final: _prev: {
    xivlauncher-rb = final.callPackage ./nixos-xivlauncher-rb { };
  };
}
