{
  _file = ./default.nix;

  perSystem =
    { self', pkgs, ... }:
    {
      apps = {
        bootstrap-nspawn = {
          type = "app";
          program = self'.packages.bootstrap-nspawn;
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
