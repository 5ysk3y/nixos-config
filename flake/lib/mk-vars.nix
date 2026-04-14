{
  perHost =
    {
      inputs,
      username,
      hostname,
      system,
    }:
    let
      isDarwin = builtins.match ".*-darwin" system != null;
      homePrefix = if isDarwin then "/Users" else "/home";
      ageKeyFile =
        if isDarwin then
          "${homePrefix}/${username}/Library/Application Support/sops/age/keys.txt"
        else
          "/var/lib/age/keys.txt";
    in
    {
      inherit username;
      flakeSource = inputs.self;
      secretsPath = builtins.toString inputs.nix-secrets;
      syncthingPath = "${homePrefix}/${username}/Sync";
      age.keyFile = "${ageKeyFile}";
    };
}
