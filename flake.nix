{
  description = "Gibson - NixOS Flake";

  inputs = {

    # Official NixOS package source, using nixos-unstable branch here
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    # nixPkgs Stable
    nixpkgs-stable = {
      url = "github:nixos/nixpkgs/nixos-25.11";
    };

    nixpkgs-old = {
      url = "github:nixos/nixpkgs/nixos-25.05";
    };

    # Other Stuff
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay/master";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    doomemacs = {
      url = "github:doomemacs/doomemacs";
      flake = false;
    };

    qute-dracula = {
      url = "github:dracula/qutebrowser";
      flake = false;
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
    };

    wayland-pipewire-idle-inhibit = {
      url = "github:rafaelrc7/wayland-pipewire-idle-inhibit";
    };

    nixos-xivlauncher-rb = {
      url = "github:drakon64/nixos-xivlauncher-rb";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-gaming = {
      url = "github:fufexan/nix-gaming";
    };

    hyprddm = {
      url = "path:./flakes/sddm-themes";
    };

    # Secrets Repo
    nix-secrets = {
      url="git+ssh://git@github.com/5ysk3y/nix-secrets.git?ref=main&shallow=1";
      flake = false;
    };
  };

  outputs = { self, ... } @inputs:
let

  vars = rec {
    username = "rickie";
    nixos-config = "/home/${username}/nixos-config";
    syncthingPath = "/home/${username}/Sync";
    secretsPath = builtins.toString inputs.nix-secrets;
  };

  pkgsFor = system: with inputs; {
    pkgs-stable = import nixpkgs-stable {
      inherit system;
      config.allowUnfree = true;
    };
    pkgs-old = import nixpkgs-old {
      inherit system;
      config.allowUnfree = true;
    };
  };

in

{

  inherit vars;
  nixosConfigurations = with inputs; {
    # Main Machine (Gibson)
    "gibson" = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = {
          hostname = "gibson";
          inherit (pkgsFor "${system}") pkgs-stable pkgs-old;
          inherit system inputs vars;
        };

      modules = with specialArgs; [
        ./hosts/${hostname}/configuration.nix
        (import ./hosts/${hostname}/overlays)
        sops-nix.nixosModules.sops # System-wide sops-nix

        # Begin Home Manager Setup
        home-manager.nixosModules.home-manager rec {
          home-manager.extraSpecialArgs = {
            inherit inputs vars doomemacs hostname pkgs-stable pkgs-old;
          };

          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.sharedModules = [
            inputs.sops-nix.homeManagerModules.sops # home-manager sops-nix
          ];

          home-manager.users.${vars.username} = with specialArgs; {
            imports = [
              ./hosts/${hostname}/home.nix
            ];
          };

        } # End Home-Manager
      ]; # End modules
    }; # End gibson

    # Testing VM (macbook)
    "macbook" = nixpkgs.lib.nixosSystem rec {
        system = "aarch64-linux";
          specialArgs = {
          hostname = "macbook";
          inherit (pkgsFor "${system}") pkgs-stable;
          inherit inputs system vars;
        };

        modules = with specialArgs; [
          ./hosts/${hostname}/configuration.nix

        # Begin Home Manager Setup
        home-manager.nixosModules.home-manager {
          home-manager.extraSpecialArgs = {
            inherit inputs vars doomemacs hostname pkgs-stable;
          };

          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.sharedModules = [
            inputs.sops-nix.homeManagerModules.sops # home-manager sops-nix
          ];

          home-manager.users.${vars.username} = with specialArgs; {
            imports = [
              ./hosts/${hostname}/home.nix
            ];
          };
        } # End Home-Manager
      ]; # End modules
    }; # End macbook
  };
};
}

