_:

{
  # claude-code itself comes from the claude-code-nix overlay, applied by
  # this feature's nixos/darwin modules (see default.nix) via the system
  # profiles.
  programs = {
    claude-code = {
      enable = true;
    };
  };
}
