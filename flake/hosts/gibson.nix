{
  inputs,
  mkVars,
  username,
}:
let
  hostname = "gibson";
  system = "x86_64-linux";
  path = ./../../hosts/gibson;
in
rec {
  kind = "nixos";
  inherit hostname system path;

  systemModule = path + /system.nix;
  homeModule = path + /home.nix;
  overlaysModule = path + /overlays;

  systemProfiles = [
    ./../../profiles/system/nixos.nix
  ];

  homeProfiles = [
    ./../../profiles/home/common.nix
    ./../../profiles/home/desktop.nix
  ];

  modules = [
    systemModule
    overlaysModule
  ];

  vars = mkVars {
    inherit
      inputs
      username
      hostname
      system
      ;
  };
}
