_: {
  # DP-1 runs at 1.25x, which drew its bar a quarter bigger than the side
  # ones. Its bar gets a 0.9x copy that style.css shrinks to match.
  features.home.waybar.scaledOutputs = [ "DP-1" ];

  programs.waybar.settings.mainBar = {
    output = [
      "DP-1"
      "DP-2"
      "HDMI-A-1"
    ];

    modules-right = [
      "group/quickHacks"
      "cpu"
      "memory"
      "temperature"
      "custom/steelseries"
      "custom/media"
      "pulseaudio"
      "clock"
    ];

    temperature = {
      "hwmon-path-abs" = "/sys/devices/pci0000:00/0000:00:18.3/hwmon/";
      "input-filename" = "temp1_input";
    };

    pulseaudio = {
      "ignored-sinks" = [
        "Starship/Matisse HD Audio Controller Analog Stereo"
      ];
    };
  };
}
