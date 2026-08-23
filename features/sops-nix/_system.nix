{
  vars,
  ...
}:
{
  sops = {
    age.keyFile = "${vars.age.keyFile}";
    defaultSopsFile = "${vars.secretsPath}/secrets/secrets.yaml";
    defaultSopsFormat = "yaml";
  };
}
