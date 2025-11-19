{
  self,
  lib,
  ...
}:
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
            sshUser = "root";
            path = self.inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.hl-vhost-x-01;
          };
        };
      };
    };
  };

  flake = {
    nixosConfigurations = {
      hl-vhost-x-01 = lib.nixosSystem {
        specialArgs = self.inputs;
        modules = [
          ./configuration.nix
        ];
      };
    };
  };

  perSystem =
    { pkgs, ... }:
    {
      packages = {
        hl-vhost-x-01 = self.nixosConfigurations.hl-vhost-x-01.config.system.build.toplevel;
      };
    };
}
