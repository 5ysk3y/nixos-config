{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages =
        lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          dim-screen = pkgs.callPackage ./dim-screen { };
          game-cleanup = pkgs.callPackage ./game-cleanup { };
          xivlauncher-rb = pkgs.callPackage ./nixos-xivlauncher-rb { };
        }
        // {
          nix-build-system = pkgs.callPackage ./nix-build-system { };
        };
    };

  flake.overlays.default = final: _prev: {
    xivlauncher-rb = final.callPackage ./nixos-xivlauncher-rb { };
  };
}
