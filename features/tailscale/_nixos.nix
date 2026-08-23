{
  config,
  ...
}:
{
  imports = [ ./_common.nix ];

  networking.firewall = {
    trustedInterfaces = [ config.services.tailscale.interfaceName ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

}
