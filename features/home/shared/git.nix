_: {
  flake.modules.homeManager.git = _: {
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
        commit.gpgsign = true;
      };

      includes = [
        {
          condition = "gitdir:~/nixos-config/**";
          contents.core.hooksPath = ".githooks";
        }
      ];

      signing.format = "openpgp";
    };
  };
}
