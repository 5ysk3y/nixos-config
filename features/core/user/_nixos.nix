# My account. Groups that come with a feature (libvirtd, gamemode, sops)
# are added by that feature; a host adds its own (hardware, password).
{ pkgs, vars, ... }:
{
  users.users.${vars.username} = {
    isNormalUser = true;
    # What NixOS gives the first normal user. Fixed so features can use it
    # (the pentesting container's user shares it).
    uid = 1000;
    description = vars.username;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "audio"
    ];
  };

  programs.zsh.enable = true;
}
