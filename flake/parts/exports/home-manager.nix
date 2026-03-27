_: {
  flake.homeManagerModules = {
    default = import ./../../../features/home;
    commonConfig = import ./../../../home/user/common.nix;
  };
}
