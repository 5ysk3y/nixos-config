# Applications too small for a directory of their own. Larger ones live in
# subdirectories here, each registering itself.
_: {
  flake.modules.homeManager = {
    ghostty = ./_ghostty.nix;
    hugo = ./_hugo.nix;
    kitty = ./_kitty.nix;
    obs-studio = ./_obs-studio.nix;
    password-management = ./_password-management.nix;
  };
}
