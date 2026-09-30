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
      aliases = {
        pr-claude = "!gh pr create -fa \"@me\" --title \"$(git log -1 --format=%s)\" --body \"$(git log -1 --format=%b | grep -viE \"^co-authored-by:\")\" \"$@\"";
        pr-create = "!gh pr create -fa \"@me\"";
      };
    };
    hosts = {
      "github.com" = {
        user = "5ysk3y";
      };
    };
  };
}
