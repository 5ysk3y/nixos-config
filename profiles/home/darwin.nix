# Home configuration for macOS
{ config, ... }:
{
  infra.profiles.homeManager.darwin.imports = with config.flake.modules.homeManager; [
    app-store
    ghostty
    macos
  ];
}
