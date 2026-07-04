{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.modules.darwin.editor
    inputs.self.modules.darwin.locale
    inputs.self.modules.darwin.nix-settings
    inputs.self.modules.darwin.overlays
    inputs.self.modules.darwin.security
    inputs.self.modules.darwin.sops-nix
    inputs.self.modules.darwin.tailscale
  ];
}
