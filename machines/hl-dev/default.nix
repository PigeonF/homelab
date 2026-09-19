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
  hl-dev-01 = mkNixOsSystem' {
    inherit system;
    nixpkgs = inputs.nixpkgs-unstable;
    specialArgs = {
      dotfiles = inputs.dotfiles-unstable;
      home-manager = inputs.home-manager-unstable;
    };
    modules = [ ./hl-dev-01.nix ];
  };
  hl-dev-02 = mkNixOsSystem' {
    inherit system;
    nixpkgs = inputs.nixpkgs-unstable;
    specialArgs = {
      dotfiles = inputs.dotfiles-unstable;
      home-manager = inputs.home-manager-unstable;
    };
    modules = [
      ./hl-dev-02.nix
    ];
  };
in
{
  _file = ./default.nix;

  deploy-rs = {
    nodes = {
      # persistent systemd-nspawn container for day-to-day development
      hl-dev-01 = {
        hostname = "hl-dev-01";
        profilesOrder = [
          "system"
        ];
        profiles = {
          system = {
            user = "root";
            sshUser = "developer";
            path = deploy-rs.activate.nixos hl-dev-01.config.system.build.images.nspawn.passthru;
          };
        };
      };
      # ephemeral systemd-vmspawn vm for evaluating untrusted code
      hl-dev-02 = {
        hostname = "hl-vhost-01";
        profilesOrder = [
          "system"
        ];
        profiles = {
          system = {
            user = "root";
            sshUser = "administrator";
            path = deploy-rs.activate.vmspawn {
              base = hl-dev-02.config.system.build.images.vmspawn;
              name = "hl-dev-02";
              limit = hl-dev-02.config.homelab.systemd-machine.limit;
            };
            profilePath = "/nix/var/nix/profiles/per-deployment/hl-dev-02";
          };
        };
      };
    };
  };

  flake = {
    nixosConfigurations = {
      inherit hl-dev-01 hl-dev-02;
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
        bootstrap-hl-dev-01 = mkApp {
          package = self'.packages.bootstrap-hl-dev-01;
          description = "Import the hl-dev-01 systemd-nspawn container directory using importctl";
        };
        bootstrap-hl-dev-02 = mkApp {
          package = self'.packages.bootstrap-hl-dev-02;
          description = "Import the hl-dev-02 systemd-vmspawn vm directory using importctl";
        };
      };
      checks =
        { }
        // (lib.optionalAttrs (system == hl-dev-01.pkgs.stdenv.hostPlatform.system) {
          hl-dev-01 = hl-dev-01.config.system.build.images.nspawn.passthru.config.system.build.toplevel;
        })
        // (lib.optionalAttrs (system == hl-dev-02.pkgs.stdenv.hostPlatform.system) {
          hl-dev-02 = hl-dev-02.config.system.build.images.vmspawn.passthru.config.system.build.toplevel;
        });
      packages = {
        bootstrap-hl-dev-01 = self'.packages.deploy-nspawn.passthru.createWrapper {
          base = hl-dev-01.config.system.build.images.nspawn;
          name = "hl-dev-01";
          limit = hl-dev-01.config.homelab.systemd-machine.limit;
        };
        bootstrap-hl-dev-02 = self'.packages.deploy-vmspawn.passthru.createWrapper {
          base = hl-dev-02.config.system.build.images.vmspawn;
          name = "hl-dev-02";
          limit = hl-dev-02.config.homelab.systemd-machine.limit;
        };
      };
    };
}
