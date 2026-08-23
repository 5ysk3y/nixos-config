{
  config,
  pkgs,
  ...
}:
{
  boot.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  services.xserver.videoDrivers = [ "nvidia" ];

  environment.sessionVariables = {
    GBM_BACKEND = "nvidia-drm";
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";
    WLR_NO_HARDWARE_CURSORS = "1";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    __GL_MaxFramesAllowed = "1";
    __GL_GSYNC_ALLOWED = "0";
    __GL_VRR_ALLOWED = "0";
  };

  hardware = {
    nvidia = {
      modesetting.enable = true;
      open = true;
      powerManagement.enable = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.latest;
    };
    graphics.extraPackages = with pkgs; [ nvidia-vaapi-driver ];
  };
}
