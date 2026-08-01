{
  pkgs,
  ...
}:

{
  stylix = {
    enable = true;
    autoEnable = false;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/dracula.yaml";
    polarity = "dark";

    cursor = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 22;
    };

    fonts = {
      monospace = {
        package = pkgs.noto-fonts;
        name = "Noto Sans Mono";
      };
      sizes.terminal = 10;
    };

    opacity.terminal = 0.87;

    targets = {
      gtk.enable = true;
      qutebrowser.enable = true;
      kitty.enable = true;
      rofi.enable = true;
    };
  };
}
