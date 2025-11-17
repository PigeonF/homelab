{ self, lib, ... }:
{
  _file = ./default.nix;

  flake = {
    nixosConfigurations = {
      hl-vhost-x-01 = lib.nixosSystem {
        modules = [
          ./configuration.nix
          {
            nixpkgs = {
              hostPlatform = "x86_64-linux";
            };
            system = {
              stateVersion = "25.11";
            };
          }
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
