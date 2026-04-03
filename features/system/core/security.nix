{
  config,
  lib,
  pkgs,
  ...
}:

{
  security = {
    pki = {
      certificates = [
        (builtins.readFile ./certs/root-ca.crt)
      ];
    };
  };
}
