{
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

  home.packages = with pkgs; [
    inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.game-cleanup
    (pkgs.xivlauncher-rb.override {
      useGameMode = true;
    })
    heroic
  ];
}
