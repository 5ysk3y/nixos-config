{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages =
        lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          dim-screen = pkgs.callPackage ./../../../pkgs/dim-screen { };
          game-cleanup = pkgs.callPackage ./../../../pkgs/game-cleanup { };
          xivlauncher-rb = pkgs.callPackage ./../../../pkgs/nixos-xivlauncher-rb { };
        }
        // {
          nix-build-system = pkgs.callPackage ./../../../pkgs/nix-build-system { };
        };
    };

  flake.overlays.default = final: _prev: {
    xivlauncher-rb = final.callPackage ./../../../pkgs/nixos-xivlauncher-rb { };
  };
}
