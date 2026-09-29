_: {
  imports = [ ./_common.nix ];

  # Only tailscaled's own WireGuard UDP port is opened. The tailnet interface
  # is deliberately not a trusted interface: a host that serves something to
  # the tailnet opens just that port on it (see attic-server), so a tailnet
  # peer — CI runners included — can't reach anything else, sshd included.
  services.tailscale.openFirewall = true;
}
