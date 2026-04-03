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
    in
    {
      inherit username;
      flakeSource = inputs.self;
      secretsPath = builtins.toString inputs.nix-secrets;
      syncthingPath = "${homePrefix}/${username}/Sync";
    };
}
