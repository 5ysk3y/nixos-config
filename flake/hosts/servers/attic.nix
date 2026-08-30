{
  inputs,
  mkVars,
  username,
}:
let
  hostname = "attic";
  system = "x86_64-linux";
  path = ./../../../hosts/servers/attic;
in
rec {
  # No home-manager, no sops-nix, no YubiKey — see registry.nix for what
  # this kind skips.
  kind = "nixos-minimal";
  inherit hostname system path;

  systemModule = path + /system.nix;
  overlaysModule = path + /overlays;

  systemProfiles = [
    ./../../../profiles/system/nixos.nix
    ./../../../profiles/system/attic-server.nix
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
