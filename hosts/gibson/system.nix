# Gibson NixOS Main Configuration
{
  config,
  pkgs,
  inputs,
  hostname,
  vars,
  ...
}:
let
  sddmTheme = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.sddm-astronaut-theme.override {
    theme = "post-apocalyptic_hacker";
  };
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  networking = {
    hostName = "${hostname}"; # Define your hostname.
    timeServers = [ "192.168.1.1" ];
    networkmanager = {
      enable = true;
    };
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

  # Define a user account. Don't forget to set a password with ‘passwd’.
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
      #   packages = with pkgs; [    ];
      #   USER PKGS MANAGED IN HOME.NIX
      shell = pkgs.zsh;
      hashedPasswordFile = config.sops.secrets."system/gibson_user_pass".path;
    };
    groups = {
      sops = { };
    };
  };

  fonts.packages = with pkgs; [
    nerd-fonts.symbols-only
    hack-font
    noto-fonts
    noto-fonts-color-emoji
    tamzen
    font-awesome
    material-design-icons
    (toString sddmTheme + "/share/fonts")

    (google-fonts.override {
      fonts = [
        "Silkscreen"
      ];
    })
  ];

  systemd = {
    tmpfiles = {
      rules = [
        "d /nix/tmp 0755 root root - -"
        "d /var/lib/age 0750 root sops - -"
        "f /var/lib/age/keys.txt 0640 root sops - -"
      ];
    };
    services = {
      "nix-daemon" = {
        environment = {
          TMPDIR = "/nix/tmp";
        };
        serviceConfig = {
          RequiresMountsFor = [
            "/nix/tmp"
          ];
        };
        restartTriggers = [
          config.environment.etc."nix/nix.conf".source
        ];
        after = [ "local-fs.target" ];
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
      lutris
      nixos-container
      nix-prefetch-github
      openssl
      pulseaudio
      sddmTheme
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
      GTK_THEME = "Dracula:dark";
      GSETTINGS_BACKEND = "keyfile";
      GBM_BACKEND = "nvidia-drm";
      NVD_BACKEND = "direct";
      LIBVA_DRIVER_NAME = "nvidia";
      WLR_NO_HARDWARE_CURSORS = "1";
      QTWEBENGINE_FORCE_USE_GBM = "0";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      __GL_MaxFramesAllowed = "1";
      __GL_GSYNC_ALLOWED = "1";
      __GL_VRR_ALLOWED = "1";
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

    pam = {
      services = {
        login = {
          u2fAuth = true;
        };

        sudo = {
          u2fAuth = true;
        };

        hyprlock = {
          u2fAuth = true;
        };

        sddm = {
          text = ''
            auth     sufficient    pam_u2f.so  cue   origin=pam://gibson appid=pam://gibson
            auth     include       login
            account  include       login
            password include       login
            session  include       login
          '';
        };
      };

      u2f = {
        enable = true;
        control = "sufficient";
        settings = {
          cue = true;
          authFile = config.sops.secrets."system/pam/yubikeyPub".path;
        };
      };
    };
  };

  # List services that you want to enable:

  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      audio.enable = true;

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

    pcscd.enable = true;
    upower.enable = true;

    dbus = {
      enable = true;
      implementation = "broker";
    };

    logind.settings.Login.HandleHibernateKey = "ignore";

    udev = {
      enable = true;
      packages = with pkgs; [
        yubikey-manager
        yubikey-personalization
        libu2f-host
      ];
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

    displayManager = {
      defaultSession = "hyprland";
      sddm = {
        enable = true;
        package = pkgs.kdePackages.sddm;
        extraPackages = with pkgs; [ kdePackages.qtmultimedia ];
        theme = "sddm-astronaut-theme";
        wayland = {
          enable = false;
        };
        settings = {
          X11 = {
            DisplayCommand = "${pkgs.writeShellScript "sddm-xsetup" ''
              #!/bin/sh
              ${pkgs.xrandr}/bin/xrandr \
                --output DP-1 --primary --auto \
                --output HDMI-A-1 --off \
                --output DP-2 --off
            ''}";
          };
        };
      };
    };

    xserver = {
      xkb.layout = "us";
      xkb.variant = "";
      videoDrivers = [ "nvidia" ];
      enable = true;
    };
  };

  # End Services

  # Start Programs

  programs = {

    dconf.enable = true;
    gamescope.enable = true;
    hyprland.enable = true;
    steam.enable = true;
    virt-manager.enable = true;
    zsh.enable = true;

    gamemode = {
      enable = true;
      enableRenice = true;
      settings = {
        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 1;
          amd_performance_level = "high";
        };
      };
    };
    gnupg = {
      agent = {
        enable = true;
        enableSSHSupport = true;
      };
    };
  };

  nix = {
    nixPath = [
      "nixpkgs=${inputs.nixpkgs}"
    ];
    package = pkgs.nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings = {
      auto-optimise-store = true;
      download-buffer-size = 1000000000; # Something that'll hopefully never get exceeded
      max-jobs = "auto";
      cores = 16;
      trusted-users = [
        "@wheel"
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      persistent = true;
      options = "--delete-older-than 7d";
    };
  };

  nixpkgs.config.allowUnfree = true;

  hardware = {
    i2c.enable = true;
    cpu.amd.updateMicrocode = true;
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };

  sops = {
    age.keyFile = "${vars.age.keyFile}";
    defaultSopsFile = "${vars.secretsPath}/secrets/secrets.yaml";
    defaultSopsFormat = "yaml";

    secrets = {

      # Yubikey
      "system/pam/yubikeyPub" = {
        owner = "${vars.username}";
      };

      # System
      "system/gibson_user_pass" = {
        neededForUsers = true;
      };
    };

  };
  system.stateVersion = "23.11"; # Did you read the comment?
}
