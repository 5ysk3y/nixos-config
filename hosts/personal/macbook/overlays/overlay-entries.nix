# Single source of truth for macbook's overlays and their audit metadata.
# See hosts/personal/gibson/overlays/overlay-entries.nix for the full convention
# explanation (exempt vs meta, final vs prev discipline).
_: {
  permanent = _final: prev: {
    # nixpkgs starts qutebrowser through a wrapper that runs its entry point
    # as a Python script, so the process's arguments are
    # `python .qutebrowser-wrapped ...`. macOS hands any plain argument to
    # the app as a file to open, and qutebrowser opened that script in a
    # tab on every launch. The patch skips it. No upstream report to track.
    qutebrowser = prev.qutebrowser.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./patches/qutebrowser-skip-entry-script.patch ];
    });
  };
  tracked = [ ];
}
