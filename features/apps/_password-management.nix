{ config, vars, ... }:
{
  # The main store's key file, kept in Syncthing
  home.file.".local/share/pass/main.gpg".source =
    config.lib.file.mkOutOfStoreSymlink "${vars.syncthingPath}/Files/nix/gnupg/main.gpg";

  programs = {
    password-store = {
      enable = true;
      settings = {
        PASSWORD_STORE_DIR = "${config.xdg.dataHome}/pass";
      };
    };

    rbw.enable = true;

    # Copies a password from the main store
    zsh.shellAliases.pass = "pass -c main";
  };
}
