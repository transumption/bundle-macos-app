{ stdenv, fetchzip, closureInfo, runCommand, writeScript, meson, ninja }:
{ name, target, icon ? null, withOpen ? false }:

let
  closure = closureInfo { rootPaths = [ stage2 ]; };

  nix-vendor = stdenv.mkDerivation rec {
    name = "nix-vendor-${version}";
    version = "86084e649d85f89f905664f67f2f197dca1f5c6a";

    src = fetchzip {
      url = "https://github.com/serokell/nix-vendor/archive/${version}.tar.gz";
      sha256 = "0g9vjddrcpzzr05pb5m162azwxf1k7k7scycv3zcznvd7k7r8b79";
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

runCommand name {} ''
  mkdir -p "$out/Applications/${name}.app" && cd $_

  for path in $(< ${closure}/store-paths); do
    cp --parents -r $path .
  done

  ${stdenv.lib.optionalString (icon != null) "cp ${icon} AppIcon.icns"}
  install ${stage1} "${name}"
''
