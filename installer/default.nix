{ self, lib, ... }:
{
  _file = ./default.nix;

  flake = {
    nixosConfigurations = {
      nixos-installer = lib.nixosSystem {
        modules = [
          ./configuration.nix
          {
            nixpkgs = {
              hostPlatform = "x86_64-linux";
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
        nixos-installer = self.nixosConfigurations.nixos-installer.config.system.build.isoImage;
      };
    };
}
