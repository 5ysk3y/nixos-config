_: {
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
      extraConfig = ''
        symbol_map U+e000-U+e00a,U+ea60-U+ebeb,U+e0a0-U+e0c8,U+e0ca,U+e0cc-U+e0d4,U+e200-U+e2a9,U+e300-U+e3e3,U+e5fa-U+e6b1,U+e700-U+e7c5,U+f000-U+f2e0,U+f300-U+f372,U+f400-U+f532,U+f0001-U+f1af0 Symbols Nerd Font Mono
        symbol_map U+2600-U+26FF Noto Color Emoji
      '';
    };
  };
}
