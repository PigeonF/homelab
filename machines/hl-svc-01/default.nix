{
  inputs,
  ...
}:
let
  system = "x86_64-linux";
  inherit (inputs.self.lib)
    mkApp
    mkNixOsSystem'
    ;
  deploy-rs = inputs.self.lib.deploy-rs' system;
  hl-svc-01 = mkNixOsSystem' {
    inherit system;
    nixpkgs = inputs.nixpkgs-unstable;
    modules = [ ./configuration.nix ];
  };
in
{
  _file = ./default.nix;

  deploy-rs = {
    nodes = {
      hl-svc-01 = {
        hostname = "hl-svc-01";
        profilesOrder = [
          "system"
        ];
        profiles = {
          system = {
            user = "root";
            sshUser = "root";
            path = deploy-rs.activate.nixos hl-svc-01.config.system.build.images.nspawn.passthru;
          };
        };
      };
    };
  };

  flake = {
    nixosConfigurations = {
      inherit hl-svc-01;
    };
  };

  perSystem =
    {
      self',
      lib,
      system,
      ...
    }:
    {
      apps = {
        bootstrap-hl-svc-01 = mkApp {
          package = self'.packages.bootstrap-hl-svc-01;
          description = "Import the hl-svc-01 systemd-nspawn container directory using importctl";
        };
      };
      checks =
        { }
        // (lib.optionalAttrs (system == hl-svc-01.pkgs.stdenv.hostPlatform.system) {
          hl-svc-01 = hl-svc-01.config.system.build.images.nspawn.passthru.config.system.build.toplevel;
        });
      packages = {
        bootstrap-hl-svc-01 = self'.packages.deploy-nspawn.passthru.createWrapper {
          base = hl-svc-01.config.system.build.images.nspawn;
          name = "hl-svc-01";
          limit = hl-svc-01.config.homelab.systemd-machine.limit;
        };
      };
    };
}
