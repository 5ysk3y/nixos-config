# Gibson NixOS Main Configuration
{
  config,
  pkgs,
  hostname,
  vars,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    inputs.self.modules.nixos.nvidia
  ];

  security.sudo.extraConfig = ''
    Defaults env_keep+=NIX_SSHOPTS
  '';

  networking = {
    useDHCP = false;
    dhcpcd.enable = false;

    hostName = hostname;
    timeServers = [ "192.168.1.1" ];

    networkmanager = {
      enable = true;
    };

    interfaces.enp7s0.useDHCP = false;

    nat = {
      enable = true;
      internalInterfaces = [ "ve-pentesting" ];
      externalInterface = "enp7s0";
    };
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  users = {
    users."${vars.username}" = {
      isNormalUser = true;
      description = "${vars.username}";
      linger = true;
      extraGroups = [
        "networkmanager"
        "wheel"
        "audio"
        "i2c"
        "libvirtd"
        "gamemode"
        "sops"
      ];
      shell = pkgs.zsh;
      hashedPasswordFile = config.sops.secrets."system/gibson_user_pass".path;
    };
    groups = {
      sops = { };
    };
  };

  systemd = {
    tmpfiles = {
      rules = [
        "d /var/lib/age 0750 root sops - -"
        "f /var/lib/age/keys.txt 0640 root sops - -"
      ];
    };
    services = {
      pcscd = {
        wantedBy = [ "multi-user.target" ];
      };
      reenable-monitors = {
        description = "Re-enable DRM outputs forced off for Plymouth boot splash";
        after = [ "plymouth-quit.service" ];
        before = [ "display-manager.service" ];
        wantedBy = [ "graphical.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "reenable-side-monitors" ''
            for conn in DP-2 HDMI-A-1; do
                for f in /sys/class/drm/card*-$conn/status; do
                [ -e "$f" ] && echo detect > "$f"
                done
            done
          '';
        };
      };
    };
  };

  # List packages installed in system profile. To search, run: $ nix search wget
  environment = {
    systemPackages = with pkgs; [
      cider-2
      ddcutil
      expect
      i2c-tools
      libmodule
      linux-firmware
      lm_sensors
      nixos-container
      nix-prefetch-github
      openssl
      pulseaudio
      v4l-utils
      vim
      xdg-utils
    ];

    sessionVariables = {
      ADW_DISABLE_PORTAL = "1";
      CLIPBOARD_NOGUI = "1";
      DOCKER_HOST = "unix://\${XDG_RUNTIME_DIR}/podman/podman.sock";
      ENABLE_DPMS = "1";
      ENABLE_DDC = "1";
      GSETTINGS_BACKEND = "keyfile";
      GTK_THEME = "adw-gtk3:dark";
    };

    pathsToLink = [
      "/share/xdg-desktop-portal"
      "/share/applications"
    ];
  };

  # Security Ruleset
  security = {
    polkit.enable = true;
    rtkit.enable = true;
  };

  services = {
    pipewire = {
      wireplumber = {
        enable = true;
        extraConfig = {
          "00-profile-enforcement" = {
            context.objects = [
              {
                factory = "policy-node";
                args = {
                  "priority.session" = 1000;
                  "target.object" = "alsa_card.pci-0000_08_00.1";
                  "target.profile" = "output:hdmi-stereo-extra1";
                };
              }
            ];
          };
          "01-default-sink" = {
            default-nodes = {
              "audio.sink" = "HDMI_External";
            };
          };
        };
      };

      extraConfig = {
        pipewire-pulse = {
          "00-combined-sink" = {
            "pulse.cmd" = [
              {
                cmd = "load-module";
                args = "module-combine-sink sink_name=HDMI_External sink_properties='device.description=\"HDMI / External\"' slaves=alsa_output.pci-0000_0a_00.4.analog-stereo,alsa_output.pci-0000_08_00.1.hdmi-stereo-extra1";
              }
            ];
          };
        };
      };
    };

    udev = {
      enable = true;
      extraRules = ''
        # SteelSeries Aerox 5
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1038", ATTRS{idProduct}=="1850", MODE="0666"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="1038", ATTRS{idProduct}=="1850", MODE="0666"

        # SteelSeries Aerox 5 Wireless (wired mode)
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1038", ATTRS{idProduct}=="1854", MODE="0666"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="1038", ATTRS{idProduct}=="1854", MODE="0666"

        # SteelSeries Aerox 5 Wireless (2.4 GHz wireless mode)
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1038", ATTRS{idProduct}=="1852", MODE="0666"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="1038", ATTRS{idProduct}=="1852", MODE="0666"

        # Logitech C920 HD Pro Webcam Default Settings
        SUBSYSTEM=="video4linux", KERNEL=="video[0-9]*", ATTR{index}=="0", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="082d", RUN+="${pkgs.v4l-utils}/bin/v4l2-ctl -d $devnode -c tilt_absolute=20000 -c zoom_absolute=150"

        # Backlight control
        KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
      '';
    };

    hardware = {
      openrgb = {
        enable = true;
        motherboard = "amd";
      };
    };
  };

  # End Services

  # Start Programs

  programs = {

    zsh.enable = true;

    gamemode.settings.gpu = {
      apply_gpu_optimisations = "accept-responsibility";
      gpu_device = 1;
      amd_performance_level = "high";
    };
  };

  nix = {
    settings = {
      cores = 16;
    };
  };

  hardware = {
    i2c.enable = true;
    cpu.amd.updateMicrocode = true;
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        ConnectionParameters = {
          MinInterval = 6;
          MaxInterval = 9;
          Latency = 44;
          Timeout = 216;
        };
      };
    };
  };

  sops = {
    secrets = {
      # System
      "system/gibson_user_pass" = {
        neededForUsers = true;
      };
    };

  };

  features.system.sddm = {
    theme = "cyberpunk";
    kwinOutputConfig = ./applications/sddm/kwinoutputconfig.json;
  };

  system.stateVersion = "23.11"; # Did you read the comment?
}
