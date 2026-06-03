{
  description = "5ysk3y's Systems Flake";

  inputs = {
    # nixpkgs repos
    # Primary: used for all NixOS and darwin builds
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Stable: used for selectively pinning packages that need stability
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";

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

    # disko
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # other stuff
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    nixos-xivlauncher-rb.url = "github:drakon64/nixos-xivlauncher-rb";
    nixos-xivlauncher-rb.inputs.nixpkgs.follows = "nixpkgs";

    emacs-overlay.url = "github:nix-community/emacs-overlay/master";
    sops-nix.url = "github:Mic92/sops-nix";
    wayland-pipewire-idle-inhibit.url = "github:rafaelrc7/wayland-pipewire-idle-inhibit";
    nix-gaming.url = "github:fufexan/nix-gaming";
    claude-code-nix.url = "github:sadjow/claude-code-nix";

    # Used as a Nix store path in features/home/doomemacs/module.nix for the
    # rsync-based activation script. The input hash drives the stamp-based
    # doom sync-skip logic — keeping as a flake input is intentional.
    doomemacs.url = "github:doomemacs/doomemacs";
    doomemacs.flake = false;

    # Used as a store path in features/home/symlinks/module.nix to symlink the
    # Dracula theme into ~/.qutebrowser and ~/.config/qutebrowser. Keeping as a
    # flake input so the path is in the Nix store and hash-pinned.
    qute-dracula.url = "github:dracula/qutebrowser";
    qute-dracula.flake = false;

    # Temporary: pins a specific nixpkgs commit to fix qtwebengine on Darwin.
    # Used only in hosts/macbook/overlays/default.nix.
    # TODO: remove once https://github.com/NixOS/nixpkgs/pull/515997 lands in
    # nixos-unstable and the macbook overlay is updated accordingly.
    qtwebengine-fix.url = "github:NixOS/nixpkgs/d233902339c02a9c334e7e593de68855ad26c4cb";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      {
        systems = [
          "x86_64-linux"
          "aarch64-darwin"
        ];
      }
      // (inputs.import-tree ./flake/parts)
    );
}
