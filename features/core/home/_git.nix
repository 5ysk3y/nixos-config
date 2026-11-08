{ vars, ... }:
{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "5ysk3y";
        email = "62815243+5ysk3y@users.noreply.github.com";
      };

      alias = {
        newpr = "!f() { git fetch origin -p && git checkout -B \"$1\" origin/main && git branch --unset-upstream; }; f";
        st = "!git status";
      };

      push = {
        default = "current";
        autoSetupRemote = true;
      };

      branch.autoSetupMerge = true;
      commit = {
        gpgsign = true;
      };
    };

    # Repo-local settings for this repo's checkout only. A trailing "/" in a
    # gitdir: pattern matches everything below it (git appends "**").
    includes = [
      {
        condition = "gitdir:${vars.configDir}/";
        contents = {
          core.hooksPath = ".githooks";
          commit.template = "${vars.configDir}/.github/gitmessage";
        };
      }
    ];

    signing.format = "openpgp";
  };
}
