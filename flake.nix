{
  description = "5ysk3y's Systems Flake";

  inputs = {
    # nixpkgs repos
    # Primary: used for all NixOS and darwin builds
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Stable: used for selectively pinning packages that need stability
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";

    # Temporary: nixpkgs master with qt6.qtwebengine 6.140.0 (NixOS/nixpkgs#587672,
    # the eMudhra fix). qutebrowser takes its Qt/Python stack from here on every
    # host until #587672 is in the locked nixpkgs. Remove alongside the
    # `qutebrowser-qtwebengine` entry in
    # features/core/system/overlays/_overlay-entries.nix.
    nixpkgs-qtwebengine.url = "github:NixOS/nixpkgs/64da148f5344e4cdc5b7d83d693b662eb834611b";

    # nix-darwin / mac related
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    mac-app-util.url = "github:hraban/mac-app-util";
    mac-app-util.inputs.nixpkgs.follows = "nixpkgs";

    # Disk partitioning at install time (nixos-anywhere / disko-install)
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # home-manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # secrets
    nix-secrets.url = "git+ssh://git@github.com/5ysk3y/nix-secrets.git?ref=main";
    nix-secrets.flake = false;

    # other stuff
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:denful/import-tree";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    wayland-pipewire-idle-inhibit.url = "github:rafaelrc7/wayland-pipewire-idle-inhibit";
    wayland-pipewire-idle-inhibit.inputs.nixpkgs.follows = "nixpkgs";
    claude-code-nix.url = "github:sadjow/claude-code-nix";
    dimland.url = "github:keifufu/dimland";
    dimland.inputs.nixpkgs.follows = "nixpkgs";

    # Used as a Nix store path in features/apps/doomemacs/_module.nix for the
    # rsync-based activation script. The input hash drives the stamp-based
    # doom sync-skip logic — keeping as a flake input is intentional.
    doomemacs.url = "github:doomemacs/core";
    doomemacs.flake = false;
    doomemacs-modules.url = "github:doomemacs/modules";
    doomemacs-modules.flake = false;

    # Built from source in features/desktop/waybar/_scripts/scroll-mpris; kept
    # as an input so the weekly flake.lock update tracks upstream.
    scroll-mpris.url = "github:BEST8OY/ScrollMPRIS";
    scroll-mpris.flake = false;

    # Add in stylix for management of GTK theming.
    stylix.url = "github:nix-community/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      # The only place top-level directories are named. Everything else is
      # discovered from here and referenced by name (config.flake.modules,
      # infra.hosts), so directories below these roots can move freely.
      imports = [
        (inputs.import-tree [
          ./flake-parts
          ./features
          ./profiles
        ])
        # Hosts: only hosts/<class>/<host>/default.nix registers a host; the
        # other .nix files there are NixOS/darwin/home modules.
        ((inputs.import-tree.match "/[^/]+/[^/]+/default\\.nix") ./hosts)
        ./pkgs
      ];
    };
}
