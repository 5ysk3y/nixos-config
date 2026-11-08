{
  pkgs,
  ...
}:
{
  fonts.packages = with pkgs; [
    nerd-fonts.symbols-only
    hack-font
    noto-fonts
    noto-fonts-color-emoji
    tamzen
    font-awesome
    material-design-icons
    (google-fonts.override { fonts = [ "Silkscreen" ]; })
  ];
}
