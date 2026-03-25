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

  systemModule = path + /configuration.nix;
  homeModule = path + /home.nix;
  overlaysModule = path + /overlays;

  systemProfiles = [
    ./../../profiles/nixos/base.nix
  ];

  homeProfiles = [
    ./../../profiles/home/common.nix
    ./../../profiles/home/gibson.nix
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
