{ config, ... }:
{
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
