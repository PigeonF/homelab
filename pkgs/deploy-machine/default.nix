{ inputs, ... }:
let
  inherit (inputs.self.lib)
    mkApp
    ;
in
{
  _file = ./default.nix;

  perSystem =
    {
      self',
      pkgs,
      ...
    }:
    {
      apps = {
        import-machine = mkApp {
          package = self'.packages.import-machine;
          description = "Import a machine (nspawn/vmspawn)";
        };
        deploy-nspawn = mkApp {
          package = self'.packages.deploy-nspawn;
          description = "Import a nspawn machine and start it";
        };
        deploy-vmspawn = mkApp {
          package = self'.packages.deploy-vmspawn;
          description = "Import a vmspawn machine and start it";
        };
      };
      packages =
        let
          packages = pkgs.callPackage ./package.nix { };
        in
        {
          inherit (packages) import-machine deploy-nspawn deploy-vmspawn;
        };
    };
}
