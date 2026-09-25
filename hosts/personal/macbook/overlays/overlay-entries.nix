# Single source of truth for macbook's overlays and their audit metadata.
# See hosts/personal/gibson/overlays/overlay-entries.nix for the full convention
# explanation (exempt vs meta, final vs prev discipline).
_: {
  permanent = _final: _prev: { };
  tracked = [
  ];
}
