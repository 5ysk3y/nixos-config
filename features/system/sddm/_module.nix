{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.features.system.sddm;

  sddm-astronaut = pkgs.sddm-astronaut.override (
    lib.optionalAttrs (cfg.theme != null) { embeddedTheme = cfg.theme; }
    // lib.optionalAttrs (cfg.themeConfig != { }) { inherit (cfg) themeConfig; }
  );
in
{
  options.features.system.sddm = {
    theme = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "sddm-astronaut-theme package variant to build; null defers to the package's own default.";
    };
    themeConfig = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Attrset of sddm-astronaut-theme config.conf key/value overrides (e.g. HeaderTextColor, Background), passed through to the package's themeConfig override.";
    };
    kwinOutputConfig = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to a host-specific kwinoutputconfig.json pinning the greeter's monitor layout; null leaves kwin's auto-detected default (clones to all outputs).";
    };
  };
  config = {
    environment.systemPackages = [ sddm-astronaut ];
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
