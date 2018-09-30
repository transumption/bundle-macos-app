{ stdenv, closureInfo, writeScript, meson, ninja }:
{ name, target, icon ? null, withOpen ? false }:

let
  closure = closureInfo { rootPaths = [ stage2 ]; };

  nix-vendor = stdenv.mkDerivation {
    name = "nix-vendor";

    src = fetchGit {
      url = https://github.com/serokell/nix-vendor;
      rev = "1af6bb5ca45b4021702647872760d32a8199bd3a";
    };

    nativeBuildInputs = [ meson ninja ];
  };

  stage1 = writeScript "stage-1" ''
    #!/bin/sh

    root=$(dirname "$0")
    root=$(dirname "$root")/Resources

    ${stdenv.lib.optionalString withOpen "open"} "$root${stage2}"
  '';

  stage2 = writeScript "stage-2" ''
    #!/bin/sh

    this=$(python -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$0")
    root=$(dirname "$this")
    root=$(dirname "$root")
    root=$(dirname "$root")

    export DYLD_INSERT_LIBRARIES="$root${nix-vendor}/lib/libnixvendor.dylib"
    export DYLD_ROOT_PATH="$root"

    exec "$root${stdenv.shell}" "$root${target}"
  '';

  plist = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>CFBundleGetInfoString</key>
      <string>${name}</string>
      <key>CFBundleExecutable</key>
      <string>${name}</string>
      <key>CFBundleIdentifier</key>
      <string>org.nixos</string>
      <key>CFBundleName</key>
      <string>${name}</string>
      <key>CFBundleInfoDictionaryVersion</key>
      <string>6.0</string>
      <key>CFBundlePackageType</key>
      <string>APPL</string>
    </dict>
  </plist>
  '';
in

stdenv.mkDerivation {
  inherit name;

  buildCommand = ''
    mkdir -p "$out/Applications/${name}.app/Contents" && cd $_
    mkdir -p MacOS Resources

    install ${stage1} "MacOS/${name}"

    for path in $(< ${closure}/store-paths); do
      cp --parents -r $path Resources
    done

    cp ${icon} "Resources/${name}.icns"
  '';

  meta = with stdenv.lib; {
    platforms = platforms.darwin;
  };
}
