{ vars, ... }:
{
  programs.hyprland.enable = true;

  services.displayManager.defaultSession = "hyprland";

  services.xserver = {
    enable = true;
    xkb.layout = "us";
    xkb.variant = "";
  };

  security.sudo.extraRules = [
    {
      users = [ vars.username ];
      commands = [
        {
          command = "/run/current-system/sw/bin/chvt";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
