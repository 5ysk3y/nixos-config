_: {
  flake.modules.homeManager = {
    base = ./_base.nix;
    git = ./_git.nix;
    gpg = ./_gpg.nix;
    nix-settings = ./_nix-settings.nix;
    ssh = ./_ssh.nix;
    zoxide = ./_zoxide.nix;
    zsh = ./_zsh.nix;
  };
}
