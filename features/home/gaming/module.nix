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

  home.packages = with pkgs; [
    inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.game-cleanup
    (inputs.nixos-xivlauncher-rb.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
      useGameMode = true;
    })
    heroic
  ];
}
