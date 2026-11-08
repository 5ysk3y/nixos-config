{
  config,
  vars,
  hostname,
  ...
}:
{
  security.pam.u2f = {
    enable = true;
    control = "sufficient";
    settings = {
      cue = true;
      origin = "pam://${hostname}";
      appid = "pam://${hostname}";
      authfile = config.sops.secrets."system/pam/yubikeyPub".path;
    };
  };

  sops.secrets."system/pam/yubikeyPub".owner = vars.username;

  services.pcscd.enable = true;
  # Started at boot as well as on demand from its socket
  systemd.services.pcscd.wantedBy = [ "multi-user.target" ];

  # gpg-agent serves SSH keys from the YubiKey: point it at the terminal
  # ssh runs in, so its PIN prompt appears there
  programs.ssh.extraConfig = ''
    Match host * exec "gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1"
  '';

  # pam_u2f: build its libfido2 without PC/SC so FIDO auth never socket-activates
  # pcscd. pcscd initialising the YubiKey's CCID reader after hibernate resume
  # makes the key answer CTAPHID ERR_CHANNEL_BUSY (0x06) to FIDO for ~20s,
  # which drops hyprlock to the password prompt. Deliberate build choice, not
  # an upstream workaround, so it lives here rather than in the audited overlays.
  nixpkgs.overlays = [
    (_final: prev: {
      pam_u2f = prev.pam_u2f.override {
        libfido2 = prev.libfido2.override { withPcsclite = false; };
      };
    })
  ];
}
