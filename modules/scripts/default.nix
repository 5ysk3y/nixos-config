{ config, lib, pkgs, vars, ... }: {

  options = with lib; {
    scripts = {
      enable = mkEnableOption "Enables Custom Scripts";
      gaming = mkOption {
        type = types.bool;
      };
      nix = mkOption {
        type = types.bool;
      };
    };
  };

  config = with lib; mkIf config.scripts.enable (mkMerge [

    (mkIf (config.scripts.gaming) {
      home.packages = with pkgs; [
        (import ./gaming {inherit pkgs;})
      ];
    })

    (mkIf (config.scripts.nix) {
      home.packages = with pkgs; [
        (import ./nix {inherit pkgs vars;})
      ];
    })
  ]);
}
