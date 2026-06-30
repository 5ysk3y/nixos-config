_: {
  flake.modules.homeManager = {
    base = ./_base.nix;
    git = ./_git.nix;
    gpg = ./_gpg.nix;
    zoxide = ./_zoxide.nix;
    zsh = ./_zsh.nix;
  };
}
