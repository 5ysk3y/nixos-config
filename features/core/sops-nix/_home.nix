# sops-nix's settings for Home Manager. Each feature declares the secrets
# it uses.
{
  pkgs,
  vars,
  ...
}:
{
  home.packages = with pkgs; [
    sops
    age
    age-plugin-yubikey
    yubikey-manager
  ];

  # So the sops command line uses the same key as sops-nix. Without it,
  # sops looks in the user config directory (~/.config/sops/age/keys.txt
  # on Linux), but gibson's key is /var/lib/age/keys.txt. The server
  # scripts in bootstrap/deploy.sh decrypt with it.
  home.sessionVariables.SOPS_AGE_KEY_FILE = vars.age.keyFile;

  sops = {
    age.keyFile = "${vars.age.keyFile}";
    defaultSopsFile = "${vars.secretsPath}/secrets/secrets.yaml";
    defaultSopsFormat = "yaml";
  };
}
