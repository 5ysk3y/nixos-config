{
  config,
  lib,
  pkgs,
  ...
}:

let
  tokenPath = config.sops.secrets."services/github-cli/token".path;

  ghWrapped = pkgs.writeShellApplication {
    name = "gh";
    text = ''
      if ! GH_TOKEN="$(cat ${lib.escapeShellArg tokenPath})"; then
       echo "gh: failed to read GitHub token from ${lib.escapeShellArg tokenPath}" >&2
         exit 1
      fi

      export GH_TOKEN
      exec ${lib.getExe pkgs.gh} "$@"
    '';
  };
in

{
  programs.gh = {
    enable = true;
    package = ghWrapped;
    settings = {
      git_protocol = "ssh";
    };
    hosts = {
      "github.com" = {
        user = "5ysk3y";
      };
    };
  };
}
