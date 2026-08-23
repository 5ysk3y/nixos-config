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

  home.packages = [
    inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.game-cleanup
    (pkgs.xivlauncher-rb.override {
      useGameMode = true;
    })
    # Wrap heroic to clear ambient CAP_SYS_NICE inherited from Hyprland's
    # security wrapper before invoking the bwrap FHS env, which refuses to
    # run when ambient caps are set without setuid.
    # Upstream: nixpkgs#526193 / nixpkgs#217119
    (pkgs.symlinkJoin {
      name = "heroic";
      paths = [
        (pkgs.writeShellScriptBin "heroic" ''
          exec ${pkgs.perl}/bin/perl \
            -e 'syscall(157,47,4,0,0,0); exec @ARGV' \
            -- ${pkgs.heroic}/bin/heroic "$@"
        '')
        pkgs.heroic # to include icons/desktop file
      ];
    })
  ];
}
