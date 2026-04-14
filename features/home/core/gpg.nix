_:
let
  ghKey = builtins.fetchurl {
    url = "https://github.com/5ysk3y.gpg";
    sha256 = "072875xvjay4ssx8g0a3f8cm51xsc4l63ls6xpjl7abzq29a5m9z";
  };
in
{
  programs.gpg = {
    enable = true;

    publicKeys = [
      {
        source = ghKey;
        trust = 5;
      }
    ];
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    enableZshIntegration = true;
    defaultCacheTtl = 600;
    maxCacheTtl = 7200;
  };
}
