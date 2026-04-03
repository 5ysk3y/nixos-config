{
  inputs,
  mkVars,
  username,
}:
let
  hostname = "macbook";
  system = "aarch64-darwin";
  path = ./../../hosts/macbook;
in
rec {
  kind = "darwin";
  inherit hostname system path;

  systemModule = path + /system.nix;
  homeModule = path + /home.nix;
  overlaysModule = path + /overlays;

  systemProfiles = [
    ./../../profiles/darwin/base.nix
  ];

  homeProfiles = [
    ./../../profiles/home/common.nix
    ./../../profiles/home/darwin.nix
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
