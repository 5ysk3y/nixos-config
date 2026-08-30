# No host-specific overlays needed for theVault. This file exists only
# because registry.nix requires every host to declare an overlaysModule
# (imported directly as a module path by flake/hosts/servers/thevault.nix).
_: { }
