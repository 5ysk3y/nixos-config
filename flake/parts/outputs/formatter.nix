{
  perSystem =
    { pkgs, ... }:
    {
      # Enables `nix fmt` to format all Nix files in the repo tree.
      formatter = pkgs.nixfmt-tree;
    };
}
