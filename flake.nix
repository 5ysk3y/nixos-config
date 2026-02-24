{
  description = "5ysk3y's Systems Flake";

  inputs = {
    # nixpkgs repos
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-old.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # nix-darwin / mac related
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    mac-app-util.url = "github:hraban/mac-app-util";

    # home-manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # secrets
    nix-secrets.url = "git+ssh://git@github.com/5ysk3y/nix-secrets.git?ref=main";
    nix-secrets.flake = false;

    # other stuff
    flake-parts.url = "github:hercules-ci/flake-parts";

    nixos-xivlauncher-rb.url = "github:drakon64/nixos-xivlauncher-rb";
    nixos-xivlauncher-rb.inputs.nixpkgs.follows = "nixpkgs";

    emacs-overlay.url = "github:nix-community/emacs-overlay/master";
    sops-nix.url = "github:Mic92/sops-nix";
    wayland-pipewire-idle-inhibit.url = "github:rafaelrc7/wayland-pipewire-idle-inhibit";
    nix-gaming.url = "github:fufexan/nix-gaming";
    sddm-themes.url = "path:./flakes/sddm-themes";

    doomemacs.url = "github:doomemacs/doomemacs";
    doomemacs.flake = false;

    qute-dracula.url = "github:dracula/qutebrowser";
    qute-dracula.flake = false;
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      imports = [
        ./flakes/parts/hosts.nix
        ./flakes/parts/modules.nix
      ];
    };
}
