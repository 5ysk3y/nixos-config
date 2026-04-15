{
  pkgs,
  ...
}:
{
  programs = {
    ghostty = {
      enable = true;
      package = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
      enableZshIntegration = true;
      installVimSyntax = true;
      settings = {
        theme = "dracula";
        font-size = 14;
        macos-option-as-alt = "left";
      };
    };
  };
}
