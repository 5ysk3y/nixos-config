# My account
{ pkgs, vars, ... }:
{
  users.users.${vars.username} = {
    home = vars.homeDirectory;
    shell = pkgs.zsh;
  };

  system.primaryUser = vars.username;
}
