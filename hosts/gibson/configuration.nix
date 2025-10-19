# Gibson NixOS Main Configuration

{ config, lib, pkgs, pkgs-stable, inputs, hostname, vars, ... }:

let

  sddmTheme = inputs.hyprddm.packages.${pkgs.system}.default.override { theme = "cyberpunk"; };

in

{ imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  networking.hostName = "${hostname}"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/London";

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


  # Configure keymap in X11
  services.xserver = { xkb.layout = "us"; xkb.variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."${vars.username}" = {
    isNormalUser = true; 
    description = "${vars.username}";
    extraGroups = [ "networkmanager" "wheel" "audio" "i2c" "libvirtd" "gamemode" ];
#   packages = with pkgs; [    ];
#   USER PKGS MANAGED IN HOME.NIX    
    shell = pkgs.zsh;
    hashedPasswordFile = config.sops.secrets."hosts/user_pass".path;
  };

  fonts.packages = with pkgs; [
    nerd-fonts.symbols-only
    hack-font
    noto-fonts
    noto-fonts-color-emoji
    tamzen
    font-awesome
    material-design-icons
    (builtins.toString sddmTheme + "/share/fonts")

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
      ];
    };
    services = {
      "configureSyncthing" = {
        enable = true;
        description = "Sets up syncthing for new installs";
        path = with pkgs; [ jq curl gawk ];
        wantedBy = [ "syncthing.service" ];
        script = "${pkgs.bash}/bin/bash ${config.sops.templates."configureSyncting.service".path}";
       };
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

    sleep = {
      extraConfig = ''
        HibernateMode=shutdown
      '';
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
      nix-prefetch-github
      openssl
      pulseaudio
      sddmTheme
      v4l-utils
      vim 
      wineWowPackages.stagingFull
      xdg-utils
      ];

    sessionVariables = rec {
      CLIPBOARD_NOGUI = "1";
      ENABLE_DPMS = "1";
      ENABLE_DDC = "1";
      ADW_DISABLE_PORTAL = "1";
      GTK_THEME = "Dracula:dark";
      GSETTINGS_BACKEND = "keyfile";
    };

    variables = rec {
      EDITOR = "emacsclient --create-frame --tty";
      AMD_VULKAN_ICD = "RADV";
    };

    pathsToLink = [
      "/share/xdg-desktop-portal" "/share/applications"
    ];
  };

  # Security Ruleset
  security = {
    rtkit = {
      enable = true;
      };

    pki = {
      certificates = [
        (builtins.readFile ../../certs/root-ca.crt)
      ];
    };

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
              auth     sufficient    pam_u2f.so  cue
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

    polkit = {
      enable = true;
     };
  };

  # List services that you want to enable:

  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;

      pulse = {
        enable = true;
      };

      audio = {
        enable = true;
      };

      wireplumber = {
        enable = true;
        extraConfig = {
          "00-profile-enforcement" = {
            context.objects = [
              {
                factory = "policy-node";
                args = {
                  "priority.session" = 1000;
                  "target.object" = "alsa_card.pci-0000_0a_00.1";
                  "target.profile" = "output:hdmi-stereo-extra4";
                };
              }
            ];
          };
          "01-default-sink" = {
            default-nodes = {
              "audio.sink" = "HDMI/External";
            };
          };
        };
      };

      extraConfig = {
        pipewire = {
          "00-combined-sink" = {
            "context.modules" = [
              {
                name = "libpipewire-module-combine-stream";
                args = {
                  "node.name" = "HDMI/External";
                  "node.description" = "HDMI/External";
                  audio.channels = 2;
                  audio.position = [ "FL" "FR" ];
                  slaves = [
                    "alsa_output.pci-0000_0a_00.1.hdmi-stereo-extra4"
                    "alsa_output.pci-0000_0c_00.4.analog-stereo"
                  ];
                };
              }
            ];
          };
        };
      };
  };
   
    pcscd = {
      enable = true;
    };

    dbus = {
      enable = true;
      implementation = "broker";
    };

    logind = {
      settings = {
        Login = {
          HandleHibernateKey = "ignore";
        };
      };
    };

    syncthing = {
      enable = true;
      user = "${vars.username}";
      dataDir = "${vars.syncthingPath}";
      configDir = "/home/${vars.username}/.config/syncthing";
      openDefaultPorts = true;
      overrideDevices = true;     # overrides any devices added or deleted through the WebUI

      key = config.sops.secrets."syncthing-key".path;
      cert = config.sops.secrets."syncthing-cert".path;

      settings = {
        options = {
          urAccepted = -1;
          relaysEnabled = false;
          globalAnnounceEnabled = false;
        };

        gui = {
          user = config.sops.secrets."services/syncthing/user";
          password = config.sops.secrets."services/syncthing/pass";
          apikey = config.sops.secrets."services/syncthing/token";
          theme = "dark";
          tls = true;
        };

        devices = {
          "SyncMaster" = {
            id = "NFYVMXE-T3IVMTV-UMLRBZ3-RQ246DT-QV3CCRG-45W5D23-EYFQFNY-Z6AH7QH";
            autoAcceptFolders = true;
          };
        };

        folders = {
          "${vars.syncthingPath}" = {
            path = "${vars.syncthingPath}";
            devices = [ "SyncMaster" ];
            id = "sync";
            label = "Sync";
            type = "receiveonly";
          };
        };
      };
    };

    udev = {
      enable = true;
      packages = with pkgs; [ pkgs-stable.yubikey-manager yubikey-personalization libu2f-host ];
      extraRules =
      ''
# SteelSeries Aerox 3
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1038", ATTRS{idProduct}=="1836", MODE="0666"
SUBSYSTEM=="usb", ATTRS{idVendor}=="1038", ATTRS{idProduct}=="1836", MODE="0666"

# SteelSeries Aerox 3 Wireless (wired mode)
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1038", ATTRS{idProduct}=="183a", MODE="0666"
SUBSYSTEM=="usb", ATTRS{idVendor}=="1038", ATTRS{idProduct}=="183a", MODE="0666"

# SteelSeries Aerox 3 Wireless (2.4 GHz wireless mode)
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1038", ATTRS{idProduct}=="1838", MODE="0666"
SUBSYSTEM=="usb", ATTRS{idVendor}=="1038", ATTRS{idProduct}=="1838", MODE="0666" 

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
          enable = true;
        };
      };
    };
  };

  # End Services

  # Start Programs

  programs = {
    hyprland = {
      enable = true;
    };

    gamescope = {
      enable = true;
    };

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

    steam = { 
      enable = true;
    };

    virt-manager = {
      enable = true;
    };

    dconf = {
      enable = true;
    };

    gnupg = {
      agent = {
        enable = true;
        enableSSHSupport = true;
      };
    };

    zsh = {
      enable = true;
    };
  };

  nix = {
    nixPath = [ 
      "nixos-config=${vars.nixos-config}/hosts/${hostname}/configuration.nix"
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
        "${vars.username}"
      ];
      substituters = [
        "https://hyprland.cachix.org"
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://nix-gaming.cachix.org"
      ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      persistent = true;
      options = "--delete-older-than 7d";
    };
  };

  # Allow unfree packages
  nixpkgs = { 
    config = {
      allowUnfree = true;
    };
  };

  hardware = {
    i2c = {
      enable = true;
    };

    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        vulkan-loader
        vulkan-validation-layers
        vulkan-extension-layer
        rocmPackages.clr.icd
      ];
      extraPackages32 = with pkgs; [
      ];
    };

    cpu = {
      amd = {
        updateMicrocode = true;
      };
    };

    amdgpu = {
      opencl = {
        enable = true;
      };
      initrd = {
        enable = true;
      };
    };

    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };

  virtualisation = {
    libvirtd = {
      enable = true;
    };
  };

  sops = {
    age.keyFile = "${vars.syncthingPath}/Private/Keys/sops-nix";
    defaultSopsFile = "${vars.secretsPath}/secrets/secrets.yaml";
    defaultSopsFormat = "yaml";

    secrets = {
      ## syncthing
      "services/syncthing/user" = {};
      "services/syncthing/pass" = {};
      "services/syncthing/token" = {};

      syncthing-cert = {
        format = "binary";
        sopsFile = "${vars.secretsPath}/secrets/syncthing/syncthing.enc.cert";
        owner = "${vars.username}";
      };

      syncthing-key = {
        format = "binary";
        sopsFile = "${vars.secretsPath}/secrets/syncthing/syncthing.enc.key";
        owner = "${vars.username}";
      };

      # Yubikey
      "system/pam/yubikeyPub" = {
        owner = "${vars.username}";
      };

      # System
      "hosts/user_pass" = {
        neededForUsers = true;
      };
    };

    templates = {
      "configureSyncting.service" = {
        content = ''
## THIS TOOK HOURS OF MY FUCKING LIFE MAN

DIR=${vars.syncthingPath}
TOKEN=${config.sops.placeholder."services/syncthing/token"}

function checkSync {
    export SYNC_PERCENTAGE=$(curl -s -X GET -H "Authorization: Bearer $TOKEN" http://localhost:8384/rest/db/completion?folder=sync | jq '."completion"' | awk -F. '{print $1}')
}

function waitSync {
    checkSync
    while [[ $SYNC_PERCENTAGE -lt 100 ]]
    do
        sleep 15
        checkSync
        echo "Sync is at $SYNC_PERCENTAGE%"
    done
    if [[ $SYNC_PERCENTAGE -eq 100 ]]; then
        echo "Synthing setup has finished. Switch builds to ensure all secrets are included."
        curl -s -X PATCH -H "Authorization: Bearer $TOKEN" http://localhost:8384/rest/config/folders/sync --data '{"type": "sendreceive"}'
    else
        echo "Sync appears to have finished synching but there's an issue. Please check it out."
        fi
}

function syncFix {
    # ENSURE that the local folder is set to "Receive Only" - it is by default.
    echo "Setting local folder to receive only"
    receiveOnly
    echo "Beginning Sync. Please wait..."
    sleep 15
    syncRevert
    sleep 15
    waitSync
}

function syncRevert {
    curl -s -X POST -H "Authorization: Bearer $TOKEN" http://localhost:8384/rest/db/scan?folder=sync
    sleep 2
    curl -s -X POST -H "Authorization: Bearer $TOKEN" http://localhost:8384/rest/db/revert?folder=sync

}

function receiveOnly {
    curl -s -X PATCH -H "Authorization: Bearer $TOKEN" http://localhost:8384/rest/config/folders/sync --data '{"type": "receiveonly"}'
}

function sendReceive {
    curl -s -o /dev/null -w "%{http_code}" -X PATCH -H "Authorization: Bearer $TOKEN" http://localhost:8384/rest/config/folders/sync --data '{"type": "sendreceive"}'
}

sleep 5
echo "Starting..."
if [ ! -d "$DIR" ]; then
    echo "No sync folder detected. Configuring..."

    receiveOnly
    mkdir -p $DIR/.stfolder
    echo "Directory created."
    chown -R ${vars.username}:users $DIR
    echo "Permissions Set."
    sleep 2

    STATUS=$(curl -s -X GET http://localhost:8384/rest/noauth/health | jq -r '."status"')
    echo "Status reports as: $STATUS"

    if [ "$STATUS" == "OK" ]; then
      echo "Starting Sync Fix"
      syncFix
    else
      echo "Check the service status of Syncthing. It shows as: $STATUS"
    fi

else
  receiveOnly
  syncRevert
  sleep 10
  checkSync
  if [[ $SYNC_PERCENTAGE -ne 100 ]]; then
    echo "Starting Sync Fix"
    syncFix
  else
    echo "Everything looks like it's already setup! Setting folder to Send/Receive mode.."
    sendReceive
    echo "All done!"
  fi

fi
      '';
      };
    };
  };

  # This value determines the NixOS release from which the default settings for stateful data, like file locations and database versions on your system were taken. It‘s perfectly fine and recommended to leave this value at the
  # release version of the first install of this system. Before changing this value read the documentation for this option (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system = {
   stateVersion = "23.11"; # Did you read the comment?
   rebuild = {
     enableNg = true;
   };
  };
}
