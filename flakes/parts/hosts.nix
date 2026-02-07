{ inputs, ... }:
let
  lib = inputs.nixpkgs.lib;
  inherit (inputs)
    nixpkgs
    nixpkgs-stable
    nixpkgs-old
    nixpkgs-darwin
    ;

  username = "rickie";

  vars = rec {
    inherit username;
    flakeSource = inputs.self;
    secretsPath = builtins.toString inputs.nix-secrets;
    syncthingPath = "/home/${username}/Sync";
  };

  hostPath = hostname: ./../../hosts/${hostname};

  pkgsFor = system: {
    pkgs-stable = import nixpkgs-stable {
      inherit system;
      config.allowUnfree = true;
    };
    pkgs-old = import nixpkgs-old {
      inherit system;
      config.allowUnfree = true;
    };
    pkgs-darwin = import nixpkgs-darwin {
      inherit system;
      config.allowUnfree = true;
    };
  };

  mkHomeManagerModule =
    {
      platformModule,
      hostname,
      extraSpecialArgs ? { },
      hmExtra ? { },
    }:
    [
      platformModule
      {
        home-manager = {
          extraSpecialArgs = {
            inherit inputs vars hostname;
            inherit (inputs) doomemacs;
          }
          // extraSpecialArgs;

          useGlobalPkgs = true;
          useUserPackages = true;

          sharedModules = [
            inputs.sops-nix.homeManagerModules.sops
          ];

          users.${vars.username} = {
            imports = [
              (hostPath hostname + /home.nix)
            ];
          };
        }
        // hmExtra;
      }
    ];

  mkNixosHost =
    { hostname, system, ... }:
    let
      p = pkgsFor system;
    in
    nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = {
        inherit
          hostname
          system
          inputs
          vars
          ;
        inherit (p) pkgs-stable pkgs-old;
      };

      modules = [
        (hostPath hostname + /configuration.nix)
        (import (hostPath hostname + /overlays))
        inputs.sops-nix.nixosModules.sops
      ]
      ++ mkHomeManagerModule {
        platformModule = inputs.home-manager.nixosModules.home-manager;
        inherit hostname;
        extraSpecialArgs = {
          inherit (p) pkgs-stable pkgs-old;
        };
      };
    };

  mkDarwinHost =
    { hostname, system, ... }:
    let
      p = pkgsFor system;
    in
    inputs.nix-darwin.lib.darwinSystem {
      inherit system;

      specialArgs = {
        inherit
          hostname
          system
          inputs
          vars
          ;
        inherit (p) pkgs-darwin;
      };

      modules = [
        (hostPath hostname + /darwin-configuration.nix)
      ]
      ++ mkHomeManagerModule {
        platformModule = inputs.home-manager.darwinModules.home-manager;
        inherit hostname;
        hmExtra = {
          backupFileExtension = "before-nix";
        };
      };
    };

  hosts = {
    gibson = {
      kind = "nixos";
      hostname = "gibson";
      system = "x86_64-linux";
    };

    macbook = {
      kind = "darwin";
      hostname = "macbook";
      system = "aarch64-darwin";
    };
  };

  filterHosts = kind: lib.filterAttrs (_: v: v.kind == kind) hosts;
  mapHosts = f: hs: lib.mapAttrs (_: v: f v) hs;

in
{
  flake = {
    nixosConfigurations = mapHosts mkNixosHost (filterHosts "nixos");
    darwinConfigurations = mapHosts mkDarwinHost (filterHosts "darwin");
  };
}
