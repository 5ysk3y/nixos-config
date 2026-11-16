# Needs flake.modules.nixos.claude-desktop on the same host: until
# NixOS/nixpkgs#587988 merges, pkgs.claude-desktop only exists through its
# overlay.
{ pkgs, ... }:
{
  home.packages = [ pkgs.claude-desktop ];
}
