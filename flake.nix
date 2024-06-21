{
  description = "Gibson - NixOS Flake";

  inputs = {

    # Official NixOS package source, using nixos-unstable branch here
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    # nixPkgs Stable
    nixpkgs-stable = {
      url = "github:nixos/nixpkgs/24.05";
    };

    nixpkgs-old = {
      url = "github:nixos/nixpkgs/23.11";
    };

    # Other Stuff

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay/master";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprlock = {
      url = "github:hyprwm/Hyprlock";
    };

    hyprland = {
      type = "git";
      url = "https://github.com/hyprwm/Hyprland?ref=v0.41.1";
      submodules = true;
    };

    hypridle = {
      url = "github:hyprwm/Hypridle";
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
      inputs.nixpkgs.follows = "nixpkgs";
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
in
{
nixosConfigurations = with inputs; {
    nixpkgs.overlays = [
      (import self.inputs.emacs-overlay)
    ];

    # Begin Main Machine (Gibson)
    "gibson" = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = {
          pkgs-stable = import nixpkgs-stable {
            system = system;
            config.allowUnfree = true;
          };
          pkgs-old = import nixpkgs-old {
            system = system;
            config.allowUnfree = true;
          };
          hostname = "gibson";
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

          home-manager.users.rickie = with specialArgs; {
            imports = [
              ./hosts/${hostname}/home.nix
            ];
          };

        } # End Home-Manager
      ]; # End modules
    }; # End gibson

    # Begin Testing VM (macbook)
    "macbook" = nixpkgs.lib.nixosSystem rec {
        system = "aarch64-linux";
        specialArgs = {
        pkgs-stable = import nixpkgs-stable {
          system = system;
          config.allowUnfree = true;
        };
        hostname = "macbook";
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

          home-manager.users.rickie = with specialArgs; {
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

