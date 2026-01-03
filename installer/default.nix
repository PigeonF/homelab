{ lib, ... }:
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
}
