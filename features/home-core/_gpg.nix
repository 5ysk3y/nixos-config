_:
let
  # Vendored copy of https://github.com/5ysk3y.gpg — avoids a network fetch
  # at eval time, and eval breaking whenever GitHub's copy changes. Update
  # it deliberately when the key (or a subkey) changes.
  ghKey = ./files/5ysk3y.asc;
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
