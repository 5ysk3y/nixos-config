{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.modules.nixos.attic-client
    inputs.self.modules.nixos.containers-pentesting
    inputs.self.modules.nixos.containers-virtualisation
    inputs.self.modules.nixos.gaming
    inputs.self.modules.nixos.hypr
    inputs.self.modules.nixos.sddm
    inputs.self.modules.nixos.sops-nix
    inputs.self.modules.nixos.tailscale
    inputs.self.modules.nixos.yubikey
  ];
}
