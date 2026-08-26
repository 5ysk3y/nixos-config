_: {
  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      audio.enable = true;
    };

    upower.enable = true;

    dbus = {
      enable = true;
      implementation = "broker";
    };

    logind.settings.Login.HandleHibernateKey = "ignore";
  };
}
