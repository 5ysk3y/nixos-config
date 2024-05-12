{ config, pkgs, lib, inputs, ... }: {

    options = with lib; {
      applications = {
          fuzzel = mkEnableOption "Enables rofi with custom configs";
      };
    };

    config = with lib; mkIf config.applications.fuzzel {
      programs = {
        fuzzel = {
          enable = true;
          settings = {
              main = {
                font = "Hack";
                lines = 10;
                width = 60;
                horizontal-pad = 20;
                inner-pad = 8;
              };
              colors = {
                background = "282a36dd";
                text = "f8f8f2ff";
                match = "8be9fdff";
                selection-match = "8be9fdff";
                selection = "44475add";
                selection-text = "f8f8f2ff";
                border = "bd93f9ff";
              };
          };
        }; # End Fuzzel
      }; # End programs
    }; # END CONFIG
}
