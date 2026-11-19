# The desktop. On Linux: Hyprland, its greeter and session services, plus the
# desktop's applications that need system support. On macOS: the system
# settings.
{ config, ... }:
{
  infra.profiles.darwin.desktop.imports = [ config.flake.modules.darwin.macos ];

  infra.profiles.nixos.desktop = {
    imports = with config.flake.modules.nixos; [
      claude-desktop
      pentesting
      virtualisation
      desktop-services
      fonts
      gaming
      hypr
      sddm
    ];
  };
}
