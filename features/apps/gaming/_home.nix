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
      device_battery = "gamepad";
    };
  };

  home.packages = [
    inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.game-cleanup
    (pkgs.xivlauncher-rb.override {
      useGameMode = true;
    })
    pkgs.heroic
  ];
}
