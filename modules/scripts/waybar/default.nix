{ config, lib, pkgs, home-manager, ... }: {

  options = with lib; {
    scripts = {
      waybar = {
        enable = mkEnableOption "Enables Custom Waybar Scripts";
        check_rbw = mkOption {
          type = types.bool;
        };

        music_panel = mkOption {
          type = types.bool;
        };

        mouse_info = mkOption {
          type = types.bool;
        };
      };
    };
  };

  config = with lib; mkIf config.scripts.waybar.enable (mkMerge [
      (mkIf (config.scripts.waybar.check_rbw) {
        home.packages = [
          (import ./check_rbw.nix {inherit pkgs;})
        ];
      })

      (mkIf (config.scripts.waybar.music_panel) {
        home.packages = [
          (import ./current_song.nix {inherit pkgs;})
          (import ./music_panel.nix {inherit pkgs;})
        ];
      })

      (mkIf (config.scripts.waybar.mouse_info) {
        home.packages = [
          (import ./mouse_battery.nix {inherit pkgs;})
          (import ./mouse_colour.nix {inherit pkgs;})
        ];
      })
  ]);
}
