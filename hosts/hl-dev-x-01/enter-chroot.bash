#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

ENV_FILTER_REGEX='(ARCH|CI|QEMU_EMULATOR|TRAVIS_.*)'

user=$(whoami)
if [ $# -ge 2 ] && [ "$1" = '-u' ]; then
    user="$2"; shift 2
fi
_sudo=''
[ "$(id -u)" -eq 0 ] || _sudo='sudo'

tmpfile="$(mktemp)"
chmod 644 "$tmpfile"
export | sed -En "s/^([^=]+ $ENV_FILTER_REGEX=)('.*'|\".*\")$/\1\3/p" > "$tmpfile" || true

cd "$(dirname "$0")"

if [ -n "${SSH_AUTH_SOCK:-}" ]; then
    if [ "$user" = "root" ]; then
        home="/root"
    else
        home="/home/$user"
    fi

    if [ ! -S "$(pwd)/$home/.ssh-auth.sock" ]; then
      $_sudo socat -d0 "UNIX-CONNECT:$SSH_AUTH_SOCK" UNIX-LISTEN:"$(pwd)/$home/.ssh-auth.sock,fork,user=$user" &
      socat_pid=$!
      trap 'kill "$socat_pid"' EXIT
    fi
    echo "export SSH_AUTH_SOCK=$home/.ssh-auth.sock" >> "$tmpfile"
fi

if [ ! -d proc ]; then
    $_sudo mkdir proc
fi

if ! mountpoint dev &>/dev/null; then
    $_sudo mkdir -p dev
    $_sudo mount -v --rbind /dev dev
    $_sudo mount --make-rprivate dev
fi

if ! mountpoint sys &>/dev/null; then
    $_sudo mkdir -p sys
    $_sudo mount -v --rbind /sys sys
    $_sudo mount --make-rprivate sys
fi

$_sudo mv "$tmpfile" env.sh
$_sudo unshare --uts --time --fork --pid --mount-proc --root "$(pwd)" \
    /usr/bin/env -i \
    sh -c "hostname alpine-chroot; exec \"\$@\"" -- \
    su -l "$user" \
    sh -c ". /etc/profile; . /env.sh; export ENV=\$HOME/.profile; exec \"\$@\"" \
    -- "${@:-sh}"
