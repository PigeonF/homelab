{
  lib,
  inputs,
  ...
}:
let
  hl-vhost-x-01 = lib.nixosSystem {
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
      hl-vhost-x-01 = {
        hostname = "hl-vhost-x-01";
        profilesOrder = [ "system" ];
        profiles = {
          system = {
            user = "root";
            sshUser = "administrator";
            path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos hl-vhost-x-01;
          };
        };
      };
    };
  };

  flake = {
    nixosConfigurations = {
      inherit hl-vhost-x-01;
    };
  };

  perSystem = _: {
    packages = {
      hl-vhost-x-01 = hl-vhost-x-01.config.system.build.toplevel;
    };
  };
}
