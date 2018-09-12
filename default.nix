{ stdenv, closureInfo, writeScript, meson, ninja }:
{ name, target, icon ? null, withOpen ? false }:

let
  closure = closureInfo { rootPaths = [ stage2 ]; };

  nix-vendor = stdenv.mkDerivation {
    name = "nix-vendor";

    src = fetchGit {
      url = "https://github.com/serokell/nix-vendor";
      rev = "a80cd5a378438e28d0760292c212b1410d408089";
    };

    nativeBuildInputs = [ meson ninja ];
  };

  stage1 = writeScript "stage-1" ''
    #!/bin/sh

    ${stdenv.lib.optionalString withOpen "open"} "$(dirname "$0")${stage2}"
  '';

  stage2 = writeScript "stage-2" ''
    #!/bin/sh

    this=$(python -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$0")
    root=$(dirname "$this")
    root=$(dirname "$root")
    root=$(dirname "$root")

    env DYLD_INSERT_LIBRARIES="$root${nix-vendor}/lib/libnixvendor.dylib" DYLD_ROOT_PATH="$root" "$root${target}"
  '';
in

stdenv.mkDerivation {
  inherit name;

  buildCommand = ''
    mkdir -p "$out/Applications/${name}.app" && cd $_

    for path in $(< ${closure}/store-paths); do
      cp --parents -r $path .
    done

    ${stdenv.lib.optionalString (icon != null) "cp ${icon} AppIcon.icns"}
    install ${stage1} "${name}"
  '';

  meta = with stdenv.lib; {
    platforms = platforms.darwin;
  };
}
