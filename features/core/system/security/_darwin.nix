_: {
  imports = [ ./_common.nix ];

  # Touch ID for sudo. reattach lets it work inside tmux and Emacs too,
  # whose sessions are cut off from the login session Touch ID needs.
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  # Refuse unrequested incoming connections, and don't answer probes such
  # as ping. Apple's signed software can still accept connections.
  networking.applicationFirewall = {
    enable = true;
    enableStealthMode = true;
  };
}
