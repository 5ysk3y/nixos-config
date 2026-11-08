{
  config,
  vars,
  pkgs,
  ...
}:
{
  programs.hyprland.enable = true;

  services.displayManager.defaultSession = "hyprland";

  # No X server: Hyprland and the SDDM greeter (kwin) are Wayland, and X11
  # apps run under XWayland. services.libinput defaults to
  # services.xserver.enable, and it's what installs libinput's udev rules
  # (device groups, quirks) that Hyprland's libinput reads, so it's kept on.
  services.libinput.enable = true;

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
