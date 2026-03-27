{
  pkgs ? import <nixpkgs> { },
}:
with pkgs;
rustPlatform.buildRustPackage {
  pname = "dim-screen";
  version = "0.4.1";
  src = fetchFromGitHub {
    owner = "marcelohdez";
    repo = "dim";
    rev = "c77e4f2fc753556627d107d83cec50d2e7c82074";
    sha256 = "sha256-5jljD0rXDplgQUvVj1zsmthBl0Fl1I0dGRrSTge+W4g=";
  };
  cargoHash = "sha256-NS/jqTukrvBa1gU42NyDMJHeyjoOCrsSo/ZbtYNeOYE=";
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ libxkbcommon ];
}
