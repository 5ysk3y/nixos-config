{ stdenv }:

stdenv.mkDerivation {
  pname = "cider-2";
  version = "manual";

  src = /nix/store/1zc1slgld6fvwbn88hvdb2fvmvxmpqav-cider-linux-x64.AppImage;

  phases = [ "installPhase" ];
  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/cider
    chmod +x $out/bin/cider
  '';
}
