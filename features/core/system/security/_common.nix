_:

{
  security = {
    pki = {
      certificates = [
        (builtins.readFile ./certs/root-ca.crt)
      ];
    };
  };
}
