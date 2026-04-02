_: {
  flake.modules.homeManager.gpg =
    _:
    let
      ghKey = builtins.fetchurl {
        url = "https://github.com/5ysk3y.gpg";
        sha256 = "1w6vml01gf81mnck4gmwi91ynkhwdsw8z84lxjlz8bvbwrj6cwrx";
      };
    in
    {
      programs.gpg.enable = true;

      services.gpg-agent = {
        enable = true;
        enableSshSupport = true;
        enableZshIntegration = true;
        defaultCacheTtl = 600;
        maxCacheTtl = 7200;
      };

      programs.gpg.publicKeys = [
        {
          source = ghKey;
          trust = 5;
        }
      ];
    };
}
