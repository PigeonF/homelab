{
  self,
  lib,
  ...
}:
{
  _file = ./default.nix;

  flake = {
    nixosConfigurations = {
      hl-vhost-x-01 = lib.nixosSystem {
        modules = [
          self.inputs.disko.nixosModules.disko
          self.inputs.nixos-facter-modules.nixosModules.facter
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
