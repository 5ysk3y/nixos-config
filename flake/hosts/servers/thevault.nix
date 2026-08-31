{
  inputs,
  mkVars,
  username,
}:
let
  hostname = "thevault";
  system = "x86_64-linux";
  path = ./../../../hosts/servers/thevault;
in
rec {
  kind = "nixos-minimal";
  inherit hostname system path;

  systemModule = path + /system.nix;
  overlaysModule = path + /overlays;

  systemProfiles = [
    ./../../../profiles/system/nixos.nix
    ./../../../profiles/system/vaultwarden.nix
    ./../../../profiles/system/zabbix-agent.nix
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
