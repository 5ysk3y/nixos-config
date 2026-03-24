_: {
  flake.homeManagerModules = {
    default = import ./../../../home/modules;
    commonConfig = import ./../../../home/user/common.nix;
  };
}
