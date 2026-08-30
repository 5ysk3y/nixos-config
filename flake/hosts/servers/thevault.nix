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
  # No home-manager, no sops-nix, no YubiKey — see registry.nix for what
  # this kind skips. Stage 1: base host only, no vaultwarden profile yet —
  # that's added in profiles/system/vaultwarden.nix once features/vaultwarden
  # exists (Stage 2).
  kind = "nixos-minimal";
  inherit hostname system path;

  systemModule = path + /system.nix;
  overlaysModule = path + /overlays;

  systemProfiles = [
    ./../../../profiles/system/nixos.nix
    ./../../../profiles/system/vaultwarden.nix
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
