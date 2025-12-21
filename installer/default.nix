{ self, lib, ... }:
{
  _file = ./default.nix;

  flake = {
    nixosConfigurations =
      let
        nixos-installer =
          hostPlatform:
          lib.nixosSystem {
            modules = [
              ./configuration.nix
              {
                nixpkgs = {
                  inherit hostPlatform;
                };
              }
            ];
          };
      in
      {
        nixos-installer-aarch64 = nixos-installer "aarch64-linux";
        nixos-installer-x86_64 = nixos-installer "x86_64-linux";
      };
  };

  perSystem = _: {
    packages = {
      nixos-installer-aarch64 =
        self.nixosConfigurations.nixos-installer-aarch64.config.system.build.isoImage;
      nixos-installer-x86_64 =
        self.nixosConfigurations.nixos-installer-x86_64.config.system.build.isoImage;
    };
  };
}
