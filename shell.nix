with import <nixpkgs> {};

stdenv.mkDerivation {
  name = "nix-macos-bundle";
  buildInputs = [ coreutils ];
}
