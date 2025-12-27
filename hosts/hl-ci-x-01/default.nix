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
      packages = {
        hl-ci-x-01 = hl-ci-x-01.config.system.build.toplevel;
      };
    };
}
