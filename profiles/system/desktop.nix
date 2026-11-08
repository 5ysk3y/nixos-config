# The Linux desktop: Hyprland, its greeter and session services, plus the
# desktop's applications that need system support
{ config, ... }:
{
  infra.profiles.nixos.desktop = {
    imports = with config.flake.modules.nixos; [
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
