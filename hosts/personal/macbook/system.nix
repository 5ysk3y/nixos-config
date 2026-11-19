{
  inputs,
  pkgs,
  ...
}:
{
  imports = with inputs.self.modules.darwin; [
    linux-builder
    wireshark
  ];

  environment.systemPackages = with pkgs; [
    nixos-rebuild
  ];

  system.stateVersion = 5;
}
