# features/system/core/sddm/module.nix
{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.features.system.sddm;

  baseTheme = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.sddm-astronaut-theme;
  sddmTheme = if cfg.theme == null then baseTheme else baseTheme.override { inherit (cfg) theme; };
in
{
  options.features.system.sddm = {
    theme = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "sddm-astronaut-theme package variant to build; null defers to the package's own default.";
    };
    kwinOutputConfig = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to a host-specific kwinoutputconfig.json pinning the greeter's monitor layout; null leaves kwin's auto-detected default (clones to all outputs).";
    };
  };

  config = {
    environment.systemPackages = [ sddmTheme ];
    fonts.packages = [ (toString sddmTheme + "/share/fonts") ];

    services.displayManager.sddm = {
      enable = true;
      wayland = {
        enable = true;
        compositor = "kwin";
      };
      package = pkgs.kdePackages.sddm;
      extraPackages = with pkgs; [ kdePackages.qtmultimedia ];
      theme = "sddm-astronaut-theme";
    };

    systemd.tmpfiles.rules = lib.optionals (cfg.kwinOutputConfig != null) [
      "f+ /var/lib/sddm/.config/kwinoutputconfig.json 644 sddm sddm - ${builtins.toJSON (builtins.fromJSON (builtins.readFile cfg.kwinOutputConfig))}"
    ];
  };
}
