{ lib, pkgs, ... }:

let
  extraSubstituters = [
    "https://nix-community.cachix.org"
    "https://nix-gaming.cachix.org"
    "http://192.168.1.110:8080/home-cache"
  ];

  extraTrustedPublicKeys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
    "home-cache:E1OhBtGAhOkDjZortT+YYKTyNZ5/gPCcaQ/ryGKUPdU="
  ];
in
{
  nix.settings = lib.mkIf pkgs.stdenv.isLinux {
    substituters = [
      "https://cache.nixos.org"
    ]
    ++ extraSubstituters;

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ]
    ++ extraTrustedPublicKeys;
  };

  environment.etc."nix/nix.custom.conf" = lib.mkIf pkgs.stdenv.isDarwin {
    text = ''
      extra-substituters = ${lib.concatStringsSep " " extraSubstituters}
      extra-trusted-public-keys = ${lib.concatStringsSep " " extraTrustedPublicKeys}
    '';
  };
}
