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

  environment.systemPackages = with pkgs; [
    nixos-rebuild
  ];

  system = {
    stateVersion = 5;
    primaryUser = "${vars.username}";
  };
}
