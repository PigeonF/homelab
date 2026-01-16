{
  lib,
  inputs,
  ...
}:
let
  hl-ci-x-03 = lib.nixosSystem {
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
      hl-ci-x-03 = {
        hostname = "hl-ci-x-03";
        profilesOrder = [
          "system"
        ];
        profiles = {
          system = {
            user = "root";
            sshUser = "root";
            path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos hl-ci-x-03;
          };
        };
      };
    };
  };

  flake = {
    nixosConfigurations = {
      inherit hl-ci-x-03;
    };
  };
}
