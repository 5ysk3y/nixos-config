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
  };
}
