# Gibson NixOS Main Configuration

{ config, lib, pkgs, inputs, hostname, vars, ... }:

{ imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./boot/bootloader.nix
    ];

  networking.hostName = "${hostname}"; # Define your hostname.
  
  # networking.wireless.enable = true; # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary 
  # networking.proxy.default = "http://user:password@proxy:port/"; 
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

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
    extraGroups = [ "networkmanager" "wheel" "audio" "clightd" "libvirtd" "gamemode" ]; 
#   packages = with pkgs; [    ];
#   USER PKGS MANAGED IN HOME.NIX    
    shell = pkgs.zsh;
    ignoreShellProgramCheck = true; # Home Manager defines user zsh configuration
    hashedPasswordFile = config.sops.secrets."hosts/user_pass".path;
  };

  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
    (google-fonts.override { fonts = [ "Silkscreen" ]; })
    hack-font
    noto-fonts
    tamzen
    roboto
  ];

  systemd = {
    services = {
      "configureSyncthing" = {
        enable = true;
        description = "Sets up syncthing for new installs";
        path = with pkgs; [ jq curl gawk ];
        wantedBy = [ "syncthing.service" ];
        script = "${pkgs.bash}/bin/bash ${config.sops.templates."configureSyncting.service".path}";
        };
      };
    };

  # List packages installed in system profile. To search, run: $ nix search wget
  environment = {
    systemPackages = with pkgs; [ 
      clightd
      clight
      ddcutil
      expect
      i2c-tools
      libmodule
      lm_sensors
      lxqt.lxqt-policykit
      nix-prefetch-github
      openssl
      pulseaudio
      v4l-utils
      vim 
      wineWowPackages.unstableFull
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
      AMD_VULKAN_ICD = "RADV";
      EDITOR="emacsclient --create-frame --tty";
    };
  };

  xdg = {
    portal = {
      enable = true;
    };
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
        };

        u2f = {
          enable = true;
          cue = true;
          control = "sufficient";
          authFile = config.sops.secrets."system/pam/yubikeyPub".path;
      };
    };

    polkit = {
      enable = true;
      extraConfig =  ''
 /* Allow any user belonging to "clightd" group to call clightd without authentication */
polkit.addRule(function(action, subject) {
  if (action.id.indexOf("org.clightd.clightd.") == 0) {
    if (subject.isInGroup("clightd")) {
      return polkit.Result.YES;
  } else {
     return polkit.Result.NO;
    }
  }
});
      '';
     };

    sudo = {
      extraRules = [
        { users = [ "${vars.username}" ];
        commands = [
          { command = "/run/current-system/sw/bin/clightd";
            options = [ "SETENV" "NOPASSWD" ]; 
          } 
        ];
       }
      ];
     };
   };

  # List services that you want to enable:

  # Enable the OpenSSH daemon. 
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
      };

      extraConfig = {
        pipewire = {
          "10-combined-audio" = {
            "context.objects" = [
                {
                factory = "adapter";
                  args = {
                    "factory.name"     = "support.null-audio-sink";
                    "node.name"        = "HDMI/External";
                    "media.class"      = "Audio/Sink";
                    "audio.position"   = [ "FL" "FR" ];
                    "monitor.channel-volumes" = "true";
                    adapter.auto-port-config = {
                      "mode" = "dsp";
                      "monitor" = "true";
                      "position" = "preserve";
                    };
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

    logind = {
      extraConfig = "IdleAction=lock";
    };

    syncthing = {
      enable = true;
      user = "${vars.username}";
      dataDir = "${vars.syncthingPath}";
      configDir = "/home/${vars.username}/.config/syncthing";
      openDefaultPorts = true;

      overrideDevices = true;     # overrides any devices added or deleted through the WebUI
      overrideFolders = true;     # overrides any folders added or deleted through the WebUI

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

    flatpak = {
      enable = true;
    };

    udev = {
      enable = true;
      packages = with pkgs; [ yubikey-personalization libu2f-host ];
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

ACTION=="remove", ENV{ID_BUS}=="usb", ENV{ID_MODEL_ID}=="0407", ENV{ID_VENDOR_ID}=="1050", ENV{ID_VENDOR}=="Yubico", RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
      '';
    };

    hardware = {
      openrgb = {
        enable = true;
        motherboard = "amd";
      };
    };
  };

  programs = {
    hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    };

    gamescope = {
      enable = true;
    };

    gamemode = {
      enable = true;
      enableRenice = true;
      settings = {
        general = {
          inhibit_screensaver = 0;
        };  
        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 0;
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

  };

  nix = {
   nixPath = [ 
     "nixos-config=${vars.nixos-config}/hosts/${hostname}/configuration.nix"
     "nixpkgs=flake:nixpkgs:/nix/var/nix/profiles/per-user/root/channels"
   ];
   package = pkgs.nixFlakes;
   extraOptions = ''
     experimental-features = nix-command flakes
   '';
   settings = {
     auto-optimise-store = true;
     substituters = [
       "https://hyprland.cachix.org"
       "https://cache.nixos.org"
       "https://nixpkgs-wayland.cachix.org"
     ];
     trusted-public-keys = [
       "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
       "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
       "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
     ];
   };
   gc = {
     automatic = true;
     dates = "weekly";
     persistent = true;
     options = "--delete-older-then 7d";
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

    cpu = {
      amd = {
        updateMicrocode = true;
      };
    };

    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
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
  system.stateVersion = "23.11"; # Did you read the comment?
}
