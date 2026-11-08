{
  inputs,
  pkgs,
  vars,
  hostname,
  ...
}:
{
  imports = [ inputs.self.modules.darwin.linux-builder ];

  networking.hostName = hostname;

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
