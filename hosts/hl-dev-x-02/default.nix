{
  lib,
  inputs,
  ...
}:
let
  hl-dev-x-02 = lib.nixosSystem {
    specialArgs = inputs;
    modules = [
      ./configuration.nix
    ];
  };
in
{
  _file = ./default.nix;

  flake = {
    nixosConfigurations = {
      inherit hl-dev-x-02;
    };
  };

  perSystem =
    { pkgs, ... }:
    {
      packages = {
        hl-dev-x-02 = hl-dev-x-02.config.system.build.toplevel;
      };
    };
}
