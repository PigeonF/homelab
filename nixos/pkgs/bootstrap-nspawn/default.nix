{
  _file = ./default.nix;

  perSystem =
    {
      self',
      lib,
      pkgs,
      ...
    }:
    {
      apps = {
        bootstrap-nspawn = {
          type = "app";
          program = lib.getExe self'.packages.bootstrap-nspawn;
          meta.description = "Bootstrap a nspawn container nixosConfiguration";
        };
      };

      packages = {
        bootstrap-nspawn = pkgs.writeShellApplication {
          name = "bootstrap-nspawn";
          text = builtins.readFile ./bootstrap-nspawn.bash;
          bashOptions = [ ];
        };
      };
    };
}
