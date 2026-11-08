{
  inputs,
  pkgs,
  ...
}:
{
  imports = [ inputs.self.modules.darwin.linux-builder ];

  environment.systemPackages = with pkgs; [
    nixos-rebuild
  ];

  system.stateVersion = 5;
}
