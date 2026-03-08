_:

{
  nixpkgs.overlays = [
    (final: prev: {
      # Temporary workaround for less 691 xterm-kitty pager regression.
      # Remove once nixpkgs includes less >= 692 everywhere we build.
      less = prev.less.overrideAttrs (_: rec {
        version = "692";
        src = prev.fetchurl {
          url = "https://www.greenwoodsoftware.com/less/less-${version}.tar.gz";
          hash = "sha256-YTAPYDeY7PHXeGVweJ8P8/WhrPB1pvufdWg30WbjfRQ=";
        };
      });
    })
  ];
}
