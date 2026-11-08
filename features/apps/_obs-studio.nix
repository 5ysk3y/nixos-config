{
  config,
  pkgs,
  vars,
  ...
}:
{
  # Scenes and profiles, kept in Syncthing
  xdg.configFile."obs-studio" = {
    source = config.lib.file.mkOutOfStoreSymlink "${vars.syncthingPath}/Files/nix/obs-studio";
    recursive = true;
  };

  programs.obs-studio = {
    enable = true;
    plugins = with pkgs; [
      obs-studio-plugins.obs-vaapi
      obs-studio-plugins.obs-pipewire-audio-capture
      obs-studio-plugins.obs-scale-to-sound
      obs-studio-plugins.obs-vkcapture
      obs-studio-plugins.obs-gstreamer
      obs-studio-plugins.obs-backgroundremoval
    ];
  };

  home.packages = with pkgs; [
    obs-cmd
  ];
}
