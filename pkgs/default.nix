let
  # Linux-only packages, defined once: published as flake packages, and
  # through overlays.default for modules (features/apps/gaming), so they
  # build against the host's own nixpkgs
  linuxPackages = pkgs: {
    game-cleanup = pkgs.callPackage ./game-cleanup { };
    xivlauncher-rb = pkgs.callPackage ./nixos-xivlauncher-rb { };
  };
in
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux (linuxPackages pkgs) // rec {
        nvd-summary = pkgs.callPackage ./nvd-summary { };
        nix-build-system = pkgs.callPackage ./nix-build-system { inherit nvd-summary; };
      };
    };

  flake.overlays.default = final: _prev: linuxPackages final;
}
