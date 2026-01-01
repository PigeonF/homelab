{
  lib,
  inputs,
  ...
}:
let
  hl-ci-x-02 = lib.nixosSystem {
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
      hl-ci-x-02 = {
        hostname = "hl-ci-x-02";
        profilesOrder = [
          "system"
        ];
        profiles = {
          system = {
            user = "root";
            sshUser = "root";
            path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos hl-ci-x-02;
          };
        };
      };
    };
  };

  flake = {
    nixosConfigurations = {
      inherit hl-ci-x-02;
    };
  };

  perSystem = {
    packages = {
      hl-ci-x-02 = hl-ci-x-02.config.system.build.toplevel;
    };
  };
}
