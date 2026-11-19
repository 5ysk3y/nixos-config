# The Mac App Store apps I use, which Nix can't install. `app-store-restore`
# installs any of them that are missing, with the account signed in to the
# App Store. mas needs root to install, so the script asks for sudo.
{ lib, pkgs, ... }:
let
  # App Store IDs: the number in an app's apps.apple.com link
  apps = {
    "Apple Configurator" = 1037126344;
    Caffeinated = 1362171212;
    "Home Assistant" = 1099568401;
    Infuse = 1136220934;
    Pages = 409201541;
    "Prime Video" = 545519333;
    "The Unarchiver" = 425424353;
    WireGuard = 1451685025;
  };
in
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "app-store-restore";
      runtimeInputs = [ pkgs.mas ];
      text = ''
        exec sudo mas install ${lib.concatMapStringsSep " " toString (lib.attrValues apps)}
      '';
    })
  ];
}
