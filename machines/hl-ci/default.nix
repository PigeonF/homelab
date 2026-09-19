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
  hl-ci-01 = mkNixOsSystem' {
    inherit system;
    nixpkgs = inputs.nixpkgs-unstable;
    modules = [ ./hl-ci-01.nix ];
  };
  hl-ci-02 = mkNixOsSystem' {
    inherit system;
    nixpkgs = inputs.nixpkgs-unstable;
    modules = [ ./hl-ci-02.nix ];
  };
in
{
  _file = ./default.nix;

  deploy-rs = {
    nodes = {
      hl-ci-01 = {
        hostname = "hl-vhost-01";
        profilesOrder = [
          "system"
        ];
        profiles = {
          system = {
            user = "root";
            sshUser = "administrator";
            path = deploy-rs.activate.nspawn {
              base = hl-ci-01.config.system.build.images.nspawn;
              name = "hl-ci-01";
              limit = hl-ci-01.config.homelab.systemd-machine.limit;
            };
            profilePath = "/nix/var/nix/profiles/per-deployment/hl-ci-01";
          };
        };
      };
      hl-ci-02 = {
        hostname = "hl-vhost-01";
        profilesOrder = [
          "system"
        ];
        profiles = {
          system = {
            user = "root";
            sshUser = "administrator";
            path = deploy-rs.activate.nspawn {
              base = hl-ci-02.config.system.build.images.nspawn;
              name = "hl-ci-02";
              limit = hl-ci-02.config.homelab.systemd-machine.limit;
            };
            profilePath = "/nix/var/nix/profiles/per-deployment/hl-ci-02";
          };
        };
      };
    };
  };

  flake = {
    nixosConfigurations = {
      inherit hl-ci-01 hl-ci-02;
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
        bootstrap-hl-ci-01 = mkApp {
          package = self'.packages.bootstrap-hl-ci-01;
          description = "Import the hl-ci-01 systemd-nspawn container directory using importctl";
        };
        bootstrap-hl-ci-02 = mkApp {
          package = self'.packages.bootstrap-hl-ci-02;
          description = "Import the hl-ci-02 systemd-nspawn container directory using importctl";
        };
      };
      checks =
        { }
        // (lib.optionalAttrs (system == hl-ci-01.pkgs.stdenv.hostPlatform.system) {
          hl-ci-01 = hl-ci-01.config.system.build.images.nspawn.passthru.config.system.build.toplevel;
        })
        // (lib.optionalAttrs (system == hl-ci-02.pkgs.stdenv.hostPlatform.system) {
          hl-ci-02 = hl-ci-02.config.system.build.images.nspawn.passthru.config.system.build.toplevel;
        });
      packages = {
        bootstrap-hl-ci-01 = self'.packages.deploy-nspawn.passthru.createWrapper {
          base = hl-ci-01.config.system.build.images.nspawn;
          name = "hl-ci-01";
          limit = hl-ci-01.config.homelab.systemd-machine.limit;
        };
        bootstrap-hl-ci-02 = self'.packages.deploy-nspawn.passthru.createWrapper {
          base = hl-ci-02.config.system.build.images.nspawn;
          name = "hl-ci-02";
          limit = hl-ci-02.config.homelab.systemd-machine.limit;
        };
      };
    };
}
