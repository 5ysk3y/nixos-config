{ config, ... }:
{
  infra.profiles.nixos.desktop = {
    imports = with config.flake.modules.nixos; [
      attic-client
      claude-code
      containers-pentesting
      containers-virtualisation
      desktop-services
      fonts
      gaming
      hypr
      sddm
      sops-nix
      tailscale
      yubikey
    ];
  };
}
