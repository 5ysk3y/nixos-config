{
  config,
  vars,
  ...
}:
{
  programs.hyprland.enable = true;

  services.displayManager.defaultSession = "hyprland";

  # hypridle suspends with suspend-then-hibernate (./_hypridle.nix). A short
  # break wakes from RAM in a second, and a long absence still ends up
  # hibernated, with the RAM powered off.
  systemd.sleep.settings.Sleep.HibernateDelaySec = "2h";

  # No X server: Hyprland and the SDDM greeter (kwin) are Wayland, and X11
  # apps run under XWayland. services.libinput defaults to
  # services.xserver.enable, and it's what installs libinput's udev rules
  # (device groups, quirks) that Hyprland's libinput reads, so it's kept on.
  services.libinput.enable = true;

  security = {
    # hyprlock runs one PAM conversation at a time and starts the next only
    # after a password is submitted. With pam_u2f in that stack, the touch
    # wait ran out a minute after locking (or broke when the YubiKey dropped
    # off USB for sleep), and the conversation sat at the password prompt
    # until a wrong password restarted it. So hyprlock's own stack is
    # password only, and the hyprlock wrapper (./_hyprlock.nix) keeps
    # retrying the YubiKey against hyprlock-u2f the whole time it's locked.
    pam.services = {
      hyprlock.u2fAuth = false;
      hyprlock-u2f = {
        u2fAuth = config.security.pam.u2f.enable;
        unixAuth = false;
      };
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
