{
  config,
  vars,
  pkgs,
  ...
}:
{
  programs.hyprland.enable = true;

  services.displayManager.defaultSession = "hyprland";

  services.xserver = {
    enable = true;
    xkb.layout = "us";
    xkb.variant = "";
  };

  security = {
    pam.services.hyprlock.rules.auth.u2f-retry = {
      order = config.security.pam.services.hyprlock.rules.auth.u2f.order + 1;
      control = "sufficient";
      modulePath = "${pkgs.pam_u2f}/lib/security/pam_u2f.so";
      inherit (config.security.pam.u2f) settings;
    };
    sudo.extraRules = [
      {
        users = [ vars.username ];
        commands = [
          {
            command = "/run/current-system/sw/bin/chvt";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
