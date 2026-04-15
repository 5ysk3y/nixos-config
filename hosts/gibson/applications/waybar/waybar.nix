_: {
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
        "Navi 21/23 HDMI/DP Audio Controller Digital Stereo (HDMI 5)"
      ];
    };
  };
}
