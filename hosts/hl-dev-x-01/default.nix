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
        ];
        profiles = {
          system = {
            user = "root";
            sshUser = "developer";
            path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos hl-dev-x-01;
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

  perSystem = {
    packages = {
      hl-dev-x-01 = hl-dev-x-01.config.system.build.toplevel;
    };
  };
}
