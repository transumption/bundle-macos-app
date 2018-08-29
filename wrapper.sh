#!/bin/sh -e

this=$(python -c "import os, sys; print(os.path.realpath(sys.argv[1]))" "$0")
root=$(dirname "$this")
root=$(dirname "$root")

sandbox-exec -D root="$root" -f "$root/etc/profile.sb" env DYLD_ROOT_PATH="$root" "$root@TARGET@" "$@"
