{
  config,
  lib,
  pkgs,
  vars,
  hostname,
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

    secrets = {
      "services/jellyfin/creds" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        path = "${config.xdg.configHome}/jellyfin-mpv-shim/cred.json";
      };

      "services/rbw/config" = lib.mkIf config.programs.rbw.enable {
        mode = "0644";
        path = "${config.xdg.configHome}/rbw/config.json";
      };

      ## syncthing
      "services/syncthing/pass" = { };
      "services/github-cli/token" = { };

      syncthing-cert = {
        format = "binary";
        sopsFile = "${vars.secretsPath}/secrets/syncthing/${hostname}.cert";
      };

      syncthing-key = {
        format = "binary";
        sopsFile = "${vars.secretsPath}/secrets/syncthing/${hostname}.key";
      };
    };
  };
}
