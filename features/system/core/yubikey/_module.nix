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
      authFile = config.sops.secrets."system/pam/yubikeyPub".path;
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
    plugins = [ pkgs.ccid ];
  };

  systemd.services.pcscd-resume = {
    description = "Restart pcscd after hibernate resume";
    wantedBy = [ "hibernate.target" ];
    after = [ "hibernate.target" ];
    script = ''
      sleep 1
      ${pkgs.systemd}/bin/systemctl restart pcscd
    '';
    serviceConfig.Type = "oneshot";
  };

  services.udev.packages = with pkgs; [
    yubikey-manager
    yubikey-personalization
    libu2f-host
  ];
}
