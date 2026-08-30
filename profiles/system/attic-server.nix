{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.modules.nixos.attic-server
    inputs.self.modules.nixos.tailscale
  ];
}
