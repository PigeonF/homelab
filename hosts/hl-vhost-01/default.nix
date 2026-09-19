{
  inputs,
  ...
}:
let
  system = "x86_64-linux";
  inherit (inputs.self.lib)
    mkNixOsSystem'
    ;
  deploy-rs = inputs.self.lib.deploy-rs' system;
  hl-vhost-01 = mkNixOsSystem' {
    inherit system;
    nixpkgs = inputs.nixpkgs-unstable;
    specialArgs = {
      inherit (inputs)
        disko
        impermanence
        nixos-facter-modules
        sops-nix
        ;
    };
    modules = [ ./configuration.nix ];
  };
in
{
  _file = ./default.nix;

  deploy-rs = {
    nodes = {
      hl-vhost-01 = {
        hostname = "hl-vhost-01";
        profilesOrder = [
          "system"
        ];
        profiles = {
          system = {
            user = "root";
            sshUser = "administrator";
            path = deploy-rs.activate.nixos hl-vhost-01;
          };
        };
      };
    };
  };

  flake = {
    nixosConfigurations = {
      inherit hl-vhost-01;
    };
  };

  # TODO(PigeonF): Add bootstrap with nixos-anywhere
  perSystem =
    {
      lib,
      system,
      ...
    }:
    {
      checks = lib.optionalAttrs (system == hl-vhost-01.pkgs.stdenv.hostPlatform.system) {
        hl-vhost-01 = hl-vhost-01.config.system.build.toplevel;
      };
    };
}
