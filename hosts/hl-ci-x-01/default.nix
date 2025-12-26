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
          "homeManager.root"
        ];
        profiles = {
          system = {
            user = "root";
            sshUser = "root";
            path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos hl-ci-x-01;
          };
          "homeManager.root" = {
            user = "root";
            sshUser = "root";
            path =
              inputs.deploy-rs.lib.x86_64-linux.activate.home-manager
                inputs.dotfiles.homeConfigurations."root@x86_64-linux";
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
      apps = {
        bootstrap-hl-ci-x-01 = {
          type = "app";
          meta = {
            description = "Bootstrap the hl-ci-x-01 container";
          };
          program = pkgs.writeShellApplication {
            name = "bootstrap-hl-ci-x-01";
            text = ''
              if [ -d /var/lib/machines/hl-ci-x-01 ]; then
                echo 1>&2 "hl-ci-x-01 machine exists already. Use deploy to update configuration"
                exit 0
              fi

              if [ "$EUID" -ne 0 ]; then
                echo 1>&2 "importctl only works with root rights. Rerun with sudo."
                exit 1
              fi

              config="''${1:-${inputs.self}#nixosConfigurations.hl-ci-x-01}"
              tarball=$(nix build -L --print-out-paths "$config.config.system.build.tarball")
              importctl -m import-tar "$tarball/tarball/nixos-system-x86_64-linux.tar.xz" hl-ci-x-01
              machinectl start hl-ci-x-01
            '';
          };
        };
      };
      packages = {
        hl-ci-x-01 = hl-ci-x-01.config.system.build.toplevel;
      };
    };
}
