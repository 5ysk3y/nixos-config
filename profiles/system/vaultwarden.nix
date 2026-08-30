{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.modules.nixos.vaultwarden
  ];
}
