{
  pkgs,
  ...
}:
{
  programs = {
    ghostty = {
      enable = true;
      package = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
      installVimSyntax = true;
      settings = {
        macos-option-as-alt = "left";
        auto-update = "off";
      };
    };
  };
}
