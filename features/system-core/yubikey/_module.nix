{
  config,
  pkgs,
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

  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
    sddm.u2fAuth = true;
    hyprlock.u2fAuth = true;
  };

  sops.secrets."system/pam/yubikeyPub".owner = vars.username;

  services.pcscd = {
    enable = true;
  };

  # pam_u2f: build its libfido2 without PC/SC so FIDO auth never socket-activates
  # pcscd. pcscd initialising the YubiKey's CCID reader after hibernate resume
  # makes the key answer CTAPHID ERR_CHANNEL_BUSY (0x06) to FIDO for ~20s,
  # which drops hyprlock to the password prompt. Deliberate build choice, not
  # an upstream workaround, so it lives here rather than in the audited overlays.
  nixpkgs.overlays = [
    (final: prev: {
      pam_u2f = prev.pam_u2f.override {
        libfido2 = prev.libfido2.override { withPcsclite = false; };
      };
    })
  ];

  services.udev.packages = with pkgs; [
    yubikey-manager
  ];
}
