# The age key at vars.age.keyFile is readable by root and the sops group
# only, and I'm in that group so sops can decrypt as me.
{ vars, ... }:
{
  imports = [ ./_system.nix ];

  users = {
    groups.sops = { };
    users.${vars.username}.extraGroups = [ "sops" ];
  };

  systemd.tmpfiles.rules = [
    "d ${dirOf vars.age.keyFile} 0750 root sops - -"
    "f ${vars.age.keyFile} 0640 root sops - -"
  ];
}
