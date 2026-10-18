{
  lib,
  pkgs,
  ...
}:

let
  extraSubstituters = [
    "https://nix-community.cachix.org"
    "https://attic.home.arpa/home-cache"
  ];

  extraTrustedPublicKeys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "home-cache:E1OhBtGAhOkDjZortT+YYKTyNZ5/gPCcaQ/ryGKUPdU="
  ];
in
{
  nix = {
    package = pkgs.nixVersions.latest;

    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    optimise = {
      automatic = true;
    };

    settings = {
      substituters = [ "https://cache.nixos.org" ] ++ extraSubstituters;
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ]
      ++ extraTrustedPublicKeys;
      download-buffer-size = 1000000000;
      max-jobs = "auto";
    };

    gc = {
      automatic = true;
      dates = lib.mkIf pkgs.stdenv.hostPlatform.isLinux "weekly";
      persistent = lib.mkIf pkgs.stdenv.hostPlatform.isLinux true;
      options = "--delete-older-than 7d";
    };
  };
}
