{
  description = "Custom OpenWrt image builder for Linksys WRT3200ACM";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    main-flake.url = "path:../../../../";
  };

  outputs = { self, nixpkgs, flake-utils, main-flake }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        vars = main-flake.outputs.vars;
      in
      {
        devShells.default = pkgs.mkShell {
          name = "openwrt-dev-shell";

          buildInputs = with pkgs; [
            gawk git unzip wget zlib libressl python3 pkg-config
            which time file perl rsync cpio gettext ncurses curl
          ];

          shellHook = ''
            export CUSTOM_PACKAGES_FILE="${vars.syncthingPath}/Private/Notes/wrt3200acm_pkgs.txt"
            cp build.sh build.sh.old
	    sed -i "s|^CUSTOM_PACKAGES_FILE=.*|CUSTOM_PACKAGES_FILE=\"''${CUSTOM_PACKAGES_FILE}\"|" ./build.sh
            echo "📦 OpenWrt dev shell ready, ${vars.username}."
            ./build.sh
            rm -rf ./imagebuilder ./build.sh.old
            exit
          '';
        };
      });
}
