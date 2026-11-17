{ pkgs, ... }:
{
  programs.mangohud = {
    enable = true;
    settings = {
      winesync = 1;
      device_battery = "gamepad";
    };
  };

  home.packages = [
    pkgs.game-cleanup
    (pkgs.xivlauncher-rb.override {
      useGameMode = true;
    })
    pkgs.heroic
  ];
}
