_:

{
  nixpkgs.overlays = [
    (_final: _prev: {
      qutebrowser = _prev.qutebrowser.overrideAttrs (_old: {
        version = "unstable-2026-08-04";
        src = _final.fetchFromGitHub {
          owner = "coderkun";
          repo = "qutebrowser";
          rev = "4c0fc4fdf6721028957cddd3075d8df09e170951";
          hash = "sha256-BVCbCSh80J7UQm5G2Ub1Ah4yzm58PYiNHR/mbSynDeE=";
        };
      });
    })
  ];
}
