{
  config,
  lib,
  pkgs,
  inputs,
  vars,
  ...
}:
{
  sops = {
    age.keyFile = "/var/lib/age/keys.txt";
    defaultSopsFile = "${vars.secretsPath}/secrets/secrets.yaml";
    defaultSopsFormat = "yaml";

    defaultSymlinkPath = "/run/user/1000/secrets";
    defaultSecretsMountPoint = "/run/user/1000/secrets.d";

    secrets = {
      "services/jellyfin/creds" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        path = "${config.xdg.configHome}/jellyfin-mpv-shim/cred.json";
      };

      "services/rbw/config" = lib.mkIf config.programs.rbw.enable {
        mode = "0644";
        path = "${config.xdg.configHome}/rbw/config.json";
      };

      ## syncthing
      "services/syncthing/user" = { };
      "services/syncthing/pass" = { };
      "services/syncthing/token" = { };

      syncthing-cert = {
        format = "binary";
        sopsFile = "${vars.secretsPath}/secrets/syncthing/syncthing.enc.cert";
      };

      syncthing-key = {
        format = "binary";
        sopsFile = "${vars.secretsPath}/secrets/syncthing/syncthing.enc.key";
      };

      "services/chatgpt/api_key" = { };
    };
  };
}
