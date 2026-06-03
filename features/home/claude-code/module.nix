{
  inputs,
  ...
}:

{

  nixpkgs.overlays = [ inputs.claude-code-nix.overlays.default ];
  programs = {
    claude-code = {
      enable = true;
    };
  };
}
