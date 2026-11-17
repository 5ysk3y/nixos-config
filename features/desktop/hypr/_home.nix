{ config, vars, ... }:
{
  imports = [
    ./_hyprland.nix
    ./_hypridle.nix
    ./_hyprlock.nix
    ./_portal.nix
  ];

  # Wallpapers for hyprlock and mpvpaper, kept in Syncthing
  xdg.configFile."Wallpapers" = {
    source = config.lib.file.mkOutOfStoreSymlink "${vars.syncthingPath}/Files/nix/Wallpapers";
    recursive = true;
  };
}
