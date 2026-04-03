{
  config,
  ...
}:
{
  programs = {
    kitty = {
      enable = true;
      themeFile = "Dracula";
      font = {
        name = "Noto Sans Mono";
        size = 10.0;
      };
      shellIntegration = {
        enableZshIntegration = true;
      };
      settings = {
        enabled_layouts = "stack";
        window_padding_width = 9;
        placement_strategy = "top-left";
        confirm_os_window_close = 3;
        background_opacity = "0.7";
      };
    };
  };
}
