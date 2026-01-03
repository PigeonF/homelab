#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

flake=""
flakeAttr=""
flakeUri=""
name=""
force=false

usage() {
  cat <<EOF
Usage: bootstrap-nspawn [options] <flake_uri> <name>

Options:

* -f, --force
  Remove the existing container image if it exists already.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
  -f | --force)
    force=true
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    if [ -z "$flakeUri" ]; then
      flakeUri="$1"
      shift
    elif [ -z "$name" ]; then
      name="$1"
      shift
    else
      usage
      exit 1
    fi
    ;;
  esac
done

if [ -z "$flakeUri" ] || [ -z "$name" ]; then
  usage
  exit 1
fi

# from https://github.com/nix-community/nixos-anywhere
if [[ "$flakeUri" =~ ^(.*)\#([^\#\"]*)$ ]]; then
  flake="${BASH_REMATCH[1]}"
  flakeAttr="${BASH_REMATCH[2]}"
fi
if [ -z "$flakeAttr" ]; then
  echo 'Please specify the name of the NixOS configuration to be installed, as a URI fragment in the flake-uri.' >&2
  echo 'For example, to use the output nixosConfigurations.foo from the flake.nix, append "#foo" to the flake-uri.' >&2
  exit 1
fi

# Support .#foo shorthand
if [[ "$flakeAttr" != nixosConfigurations.* ]]; then
  flakeAttr="nixosConfigurations.\"$flakeAttr\""
fi

if [ -d "/var/lib/machines/$name" ]; then
  echo "A machine with name '$name' exists already." >&2
  if [ "$force" = true ]; then
    if machinectl list | grep -q "$name"; then
      echo "Stopping running machine '$name'." >&2
      machinectl stop "$name"
    fi
    echo "Removing machine '$name'" >&2
    machinectl remove "$name"
  else
    echo "Remove the machine with 'machinectl remove $name' or re-run bootstrap-nspawn with '--force'" >&2
    exit 1
  fi
fi

tarball=$(nix build -L --print-out-paths "$flake#$flakeAttr.config.system.build.tarball")
importctl -m import-tar "$tarball/tarball/nixos-system-"*.tar.xz "$name"
