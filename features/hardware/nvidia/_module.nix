{
  config,
  pkgs,
  ...
}:
{
  # Loaded here because the NVIDIA module only adds nvidia, nvidia_modeset
  # and nvidia_drm to boot.kernelModules while services.xserver.enable is on,
  # and there's no X server (features/desktop/hypr). nvidia_drm is what gives
  # Hyprland its DRM device.
  boot.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  # How the NVIDIA module is switched on, X server or not
  services.xserver.videoDrivers = [ "nvidia" ];

  environment.sessionVariables = {
    GBM_BACKEND = "nvidia-drm";
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    __GL_MaxFramesAllowed = "1";
    # VRR is left to each host's Hyprland monitor rules (gibson: vrr = 2,
    # fullscreen only); __GL_VRR_ALLOWED=0 here would opt every GL app out
  };

  hardware = {
    nvidia = {
      modesetting.enable = true;
      open = true;
      powerManagement.enable = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.production;
    };
    graphics.extraPackages = with pkgs; [ nvidia-vaapi-driver ];
  };
}
