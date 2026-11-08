_: {
  security = {
    polkit.enable = true;
    # Lets PipeWire raise its threads to realtime priority
    rtkit.enable = true;
  };

  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    upower.enable = true;

    dbus = {
      enable = true;
      implementation = "broker";
    };

    logind.settings.Login.HandleHibernateKey = "ignore";
  };
}
