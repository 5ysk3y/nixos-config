{
  config,
  pkgs,
  ...
}:
{
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs; [
      obs-studio-plugins.obs-vaapi
      obs-studio-plugins.obs-pipewire-audio-capture
      obs-studio-plugins.obs-scale-to-sound
      obs-studio-plugins.obs-vkcapture
      obs-studio-plugins.obs-gstreamer
    ];
  };

  home.packages = with pkgs; [
    obs-cmd
  ];
}
