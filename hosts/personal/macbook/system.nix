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

  # The name shown in Finder, AirDrop and Bluetooth. The network names
  # come from the hostname.
  networking.computerName = "MacBook Air";

  system.stateVersion = 5;
}
