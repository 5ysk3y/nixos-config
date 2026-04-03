{
  config,
  pkgs,
  inputs,
  ...
}:
{
  programs.mangohud = {
    enable = true;
    settings = {
      winesync = 1;
    };
  };

  home.packages = [
    inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.game-cleanup
  ];
}
