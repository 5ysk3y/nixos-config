{
  lib,
  pkgs,
  inputs,
  ...
}:

let
  extraSubstituters = [
    "https://nix-community.cachix.org"
    "https://nix-gaming.cachix.org"
    "https://attic.home.arpa/home-cache"
  ];

  extraTrustedPublicKeys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
    "home-cache:E1OhBtGAhOkDjZortT+YYKTyNZ5/gPCcaQ/ryGKUPdU="
  ];
in
{
  nix = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
    package = pkgs.nixVersions.latest;

    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    settings = {
      substituters = [ "https://cache.nixos.org" ] ++ extraSubstituters;
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ]
      ++ extraTrustedPublicKeys;
      auto-optimise-store = true;
      download-buffer-size = 1000000000;
      max-jobs = "auto";
      trusted-users = [ "@wheel" ];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      persistent = true;
      options = "--delete-older-than 7d";
    };
  };

  environment.etc."nix/nix.custom.conf" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    text = ''
      extra-substituters = ${lib.concatStringsSep " " extraSubstituters}
      extra-trusted-public-keys = ${lib.concatStringsSep " " extraTrustedPublicKeys}
      experimental-features = nix-command flakes
    '';
  };
}
