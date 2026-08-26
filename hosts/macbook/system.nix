{
  pkgs,
  vars,
  hostname,
  ...
}:
{

  networking.hostName = hostname;

  nix = {
    enable = false;
  };

  users.users.${vars.username} = {
    home = "/Users/${vars.username}";
    shell = pkgs.zsh;
  };

  services.openssh.enable = false;

  system = {
    stateVersion = 5;
    primaryUser = "${vars.username}";
  };
}
