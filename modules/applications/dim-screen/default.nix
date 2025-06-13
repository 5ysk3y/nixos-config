{ pkgs ? import <nixpkgs> {} }:

with pkgs;

rustPlatform.buildRustPackage {
  pname = "dim-screen";
  version = "0.3.0";
  src = fetchFromGitHub {
    owner = "marcelohdez";
    repo = "dim";
    rev = "c516aaa0482e9aec2cce1bdb42c8186c87b37379";
    sha256 = "sha256-n1CV4Gge7ugjaMIv3MHbh6Yg6ofvmjYi5046CnI8BPE=";
  };
  useFetchCargoVendor = true;
  cargoHash = "sha256-iQT5RwL7me1vusvSyBxqgRK+Dpk+FDn7F6w+VtWCHZc=";
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ libxkbcommon ];
}
