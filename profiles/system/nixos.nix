{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.modules.nixos.editor
    inputs.self.modules.nixos.locale
    inputs.self.modules.nixos.nix-settings
    inputs.self.modules.nixos.overlays
    inputs.self.modules.nixos.security
    inputs.self.modules.nixos.yubikey
    inputs.self.modules.nixos.containers-pentesting
    inputs.self.modules.nixos.containers-virtualisation
  ];
}
