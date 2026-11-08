# Applications too small for a directory of their own. Larger ones live in
# subdirectories here, each registering itself.
_: {
  flake.modules.homeManager = {
    bitwarden = ./_bitwarden.nix;
    ghostty = ./_ghostty.nix;
    hugo = ./_hugo.nix;
    kitty = ./_kitty.nix;
    messaging = ./_messaging.nix;
    obs-studio = ./_obs-studio.nix;
    password-management = ./_password-management.nix;
  };
}
