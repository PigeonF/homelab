{
  lib,
  inputs,
  ...
}:
let
  hl-ci-x-01 = lib.nixosSystem {
    specialArgs = inputs;
    modules = [
      ./configuration.nix
    ];
  };
in
{
  _file = ./default.nix;

  deploy-rs = {
    nodes = {
      hl-ci-x-01 = {
        hostname = "hl-ci-x-01";
        profilesOrder = [
          "system"
        ];
        profiles = {
          system = {
            user = "root";
            sshUser = "root";
            path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos hl-ci-x-01;
          };
        };
      };
    };
  };

  flake = {
    nixosConfigurations = {
      inherit hl-ci-x-01;
    };
  };

  perSystem =
    { pkgs, ... }:
    {
      packages = {
        hl-ci-x-01 = hl-ci-x-01.config.system.build.toplevel;

        alpine-enter-chroot = pkgs.writeShellApplication {
          name = "enter-chroot";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.socat
          ];
          text = ''
            ENV_FILTER_REGEX='(ARCH|CI|QEMU_EMULATOR|TRAVIS_.*)'

            user=$(whoami)
            if [ $# -ge 2 ] && [ "$1" = '-u' ]; then
                user="$2"; shift 2
            fi
            oldpwd="$(pwd)"
            [ "$(id -u)" -eq 0 ] || _sudo='sudo'

            tmpfile="$(mktemp)"
            chmod 644 "$tmpfile"
            export | sed -En "s/^([^=]+ $ENV_FILTER_REGEX=)('.*'|\".*\")$/\1\3/p" > "$tmpfile" || true


            cd "$(dirname "$0")"

            if [ -n "$SSH_AUTH_SOCK" ]; then
                if [ "$user" = "root" ]; then
                    home="/root"
                else
                    home="/home/$user"
                fi
                socat "UNIX-CONNECT:$SSH_AUTH_SOCK" UNIX-LISTEN:"$(pwd)/$home/.ssh-auth.sock,fork,user=$user" &
                socat_pid=$!
                trap 'kill "$socat_pid"' EXIT
                echo "export SSH_AUTH_SOCK=$home/.ssh-auth.sock" >> "$tmpfile"
            fi

            $_sudo mv "$tmpfile" env.sh
            $_sudo chroot . /usr/bin/env -i su -l "$user" \
                sh -l -c ". /etc/profile; . /env.sh; cd '$oldpwd' 2>/dev/null; export ENV=\$HOME/.profile; \"\$@\"" \
                -- "''${@:-sh}"
          '';
        };
      };
    };
}
