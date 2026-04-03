{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = lib.optionalAttrs pkgs.stdenv.isLinux {
        dim-screen = pkgs.callPackage ./../../../pkgs/dim-screen { };
        sddm-astronaut-theme = pkgs.callPackage ./../../../pkgs/sddm-themes { };
        game-cleanup = pkgs.callPackage ./../../../pkgs/game-cleanup { };
        nix-build-system = pkgs.callPackage ./../../../pkgs/nix-build-system { };
      };
    };
}
