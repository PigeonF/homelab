{
  inputs,
  ...
}:
let
  hl-dev-x-02 = inputs.self.lib.mkNixOsSystem {
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
}
