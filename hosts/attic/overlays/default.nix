# No host-specific overlays needed for attic. This file exists only
# because registry.nix requires every host to declare an overlaysModule
# (imported directly as a module path by flake/hosts/attic.nix).
_: { }
