{
  lib,
  inputs,
  ...
}:
let
  hl-dev-x-01 = lib.nixosSystem {
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
      hl-dev-x-01 = {
        hostname = "hl-dev-x-01";
        profilesOrder = [
          "system"
          "homeManager.root"
          "homeManager.developer"
        ];
        profiles = {
          system = {
            user = "root";
            sshUser = "developer";
            path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos hl-dev-x-01;
          };
          "homeManager.root" = {
            user = "root";
            sshUser = "developer";
            path =
              inputs.deploy-rs.lib.x86_64-linux.activate.home-manager
                inputs.dotfiles.homeConfigurations."root@x86_64-linux";
          };
          "homeManager.developer" = {
            user = "developer";
            sshUser = "developer";
            path =
              inputs.deploy-rs.lib.x86_64-linux.activate.home-manager
                inputs.dotfiles.homeConfigurations."developer@hl-dev-x-01";
          };
        };
      };
    };
  };

  flake = {
    nixosConfigurations = {
      inherit hl-dev-x-01;
    };
  };

  perSystem =
    { pkgs, ... }:
    {
      apps = {
        bootstrap-hl-dev-x-01 = {
          type = "app";
          meta = {
            description = "Bootstrap the hl-dev-x-01 container";
          };
          program = pkgs.writeShellApplication {
            name = "bootstrap-hl-dev-x-01";
            text = ''
              if [ -d /var/lib/machines/hl-dev-x-01 ]; then
                echo 1>&2 "hl-dev-x-01 machine exists already. Use deploy to update configuration"
                exit 0
              fi

              if [ "$EUID" -ne 0 ]; then
                echo 1>&2 "importctl only works with root rights. Rerun with sudo."
                exit 1
              fi

              config="''${1:-${inputs.self}#nixosConfigurations.hl-dev-x-01}"
              tarball=$(nix build -L --print-out-paths "$config.config.system.build.tarball")
              importctl -m import-tar "$tarball/tarball/nixos-system-x86_64-linux.tar.xz" hl-dev-x-01
              machinectl start hl-dev-x-01
            '';
          };
        };
      };
      packages = {
        hl-dev-x-01 = hl-dev-x-01.config.system.build.toplevel;
      };
    };
}
