_: {
  flake.modules.homeManager = {
    base = ./base.nix;
    git = ./git.nix;
    gpg = ./gpg.nix;
    zoxide = ./zoxide.nix;
    zsh = ./zsh.nix;
  };
}
