{
  pkgs,
  modulesPath,
  system,
  vars,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    kernelModules = [
      "ntsync"
    ];
    blacklistedKernelModules = [
      "ath12k_pci"
      "ath12k"
    ];
    kernelParams = [
      "quiet"
      "splash"
      "acpi_enforce_resources=lax"
      "video=DP-1:2560x1440@144"
      "video=DP-2:d"
      "video=HDMI-A-1:d"
      "zswap.enabled=1"
      "zswap.compressor=lz4"
      "zswap.max_pool_percent=20"
      "zswap.shrinker_enabled=1"
      "pcie_aspm=off"
    ];
    extraModulePackages = [ ];
    loader = {
      timeout = 0;
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
      };
      efi.canTouchEfiVariables = true;
    };
    # The system disk's LUKS device, filesystems, swap and resume device
    # come from disko.nix
    initrd = {
      kernelModules = [
      ];
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usbhid"
        "sd_mod"
      ];
    };
    plymouth = {
      enable = true;
      theme = "hexagon_hud";
      themePackages = with pkgs; [
        (adi1090x-plymouth-themes.override {
          selected_themes = [ "hexagon_hud" ];
        })
      ];
    };
    consoleLogLevel = 3;
  };

  # The games disk; the system disk is in disko.nix
  fileSystems."/home/${vars.username}/games" = {
    device = "/dev/disk/by-label/GAMES";
    fsType = "ext4";
  };

  hardware = {
    enableAllFirmware = true;

    graphics = {
      enable = true;
      enable32Bit = true;
    };

  };

  nixpkgs.hostPlatform = "${system}";
}
