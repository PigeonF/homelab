{
  inputs,
  ...
}:
let
  hl-ci-x-03 = inputs.self.lib.mkNixOsSystem {
    modules = [
      ./configuration.nix
    ];
  };
in
{
  _file = ./default.nix;

  deploy-rs = {
    nodes = {
      hl-ci-x-03 = {
        hostname = "hl-vhost-x-01";
        profilesOrder = [
          "system"
        ];
        profiles = {
          system = {
            user = "root";
            sshUser = "administrator";
            path =
              let
                activateNspawn = inputs.self.lib.deploy-rs.activateNspawn hl-ci-x-03.pkgs.stdenv.hostPlatform.system;
              in
              activateNspawn hl-ci-x-03;
            profilePath = "/nix/var/nix/profiles/per-container/hl-ci-x-03";
          };
        };
      };
    };
  };

  flake = {
    nixosConfigurations = {
      inherit hl-ci-x-03;
    };
  };
}
