{
  description = "Nix configurations for my homelab";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=refs/heads/release-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=refs/heads/master";
    systems.url = "github:nix-systems/default?ref=refs/heads/main";

    deploy-rs = {
      url = "github:serokell/deploy-rs?ref=refs/heads/master";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "flake-utils";
    };
    disko = {
      # url = "github:nix-community/disko?ref=refs/heads/master";
      url = "github:PigeonF/disko?ref=refs/heads/push-lmlquwslzsyn"; # https://github.com/nix-community/disko/issues/1099
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dotfiles = {
      url = "github:PigeonF/dotfiles?ref=refs/heads/main";
      inputs.deploy-rs.follows = "deploy-rs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.flake-utils.follows = "flake-utils";
      inputs.home-manager.follows = "home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-unstable.follows = "nixpkgs-unstable";
      inputs.systems.follows = "systems";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };
    dotfiles-unstable = {
      url = "github:PigeonF/dotfiles?ref=refs/heads/main";
      inputs.deploy-rs.follows = "deploy-rs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.flake-utils.follows = "flake-utils";
      inputs.home-manager.follows = "home-manager-unstable";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.nixpkgs-unstable.follows = "nixpkgs-unstable";
      inputs.systems.follows = "systems";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts?ref=refs/heads/main";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    flake-utils = {
      url = "github:numtide/flake-utils?ref=refs/heads/main";
      inputs.systems.follows = "systems";
    };
    home-manager = {
      url = "github:nix-community/home-manager?ref=refs/heads/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-unstable = {
      url = "github:nix-community/home-manager?ref=refs/heads/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    impermanence = {
      url = "github:nix-community/impermanence?ref=refs/heads/master";
      inputs.home-manager.follows = "home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-facter-modules = {
      url = "github:nix-community/nixos-facter-modules?ref=refs/heads/main";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix?ref=refs/heads/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix?ref=refs/heads/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      flake-parts,
      systems,
      treefmt-nix,
      ...
    }:
    flake-parts.lib.mkFlake
      {
        inherit inputs;
      }
      (_: {
        _file = ./flake.nix;

        systems = import systems;

        imports = [
          treefmt-nix.flakeModule
          # ./hosts
          ./hosts/hl-vhost-01
          ./installer
          ./machines/hl-ci
          ./machines/hl-dev
          ./machines/hl-svc-01
          ./modules
          # ./nixos
          ./pkgs/deploy-machine
          ./pkgs/systemd-vmspawn-ssh-proxy
        ];

        flake = {
          lib = {
            mkNixOsSystem' = import ./lib/mk-nixos-configuration.nix { inherit inputs; };
            mkApp = import ./lib/mk-app.nix { lib = inputs.nixpkgs.lib; };
            deploy-rs' = import ./lib/deploy-rs.nix { inherit inputs; };
            mkNixOsSystem =
              args@{
                specialArgs ? { },
                homelabModulesPath ? ./nixos/modules,
                nixpkgs ? inputs.nixpkgs,
                ...
              }:
              nixpkgs.lib.nixosSystem (
                {
                  specialArgs = {
                    inherit homelabModulesPath inputs;
                  }
                  // specialArgs;
                }
                // builtins.removeAttrs args [
                  "nixpkgs"
                  "specialArgs"
                ]
              );

            deploy-rs = {
              activateNspawn =
                system: base:
                inputs.deploy-rs.lib.${system}.activate.custom base.config.system.build.images.nspawn-image ''
                  baseName="${base.config.system.build.images.nspawn-image.passthru.config.image.baseName}"
                  importctl -m import-raw "$PROFILE/$baseName.raw" --force --quiet
                  systemctl reload-or-restart "systemd-nspawn@$baseName"
                '';
            };
          };
          nixosModules = {
            nspawn' = ./modules/nixos/nspawn.nix;
            nspawnImage = ./modules/nixos/image/nspawn.nix;
            vmspawnImage = ./modules/nixos/image/vmspawn.nix;
          };
          overlays = {
            patchedPackages = final: _: {
              patchedPackages = {
                gitlab-runner = final.callPackage ./overlays/gitlab-runner { };
              };
            };
          };
        };

        perSystem =
          {
            self',
            lib,
            pkgs,
            system,
            ...
          }:
          {
            _module.args.pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = builtins.attrValues inputs.self.overlays ++ [
                inputs.dotfiles.overlays.sdk-apple-darwin
                inputs.dotfiles.overlays.sdk-pc-windows-msvc
              ];
            };

            treefmt = import ./treefmt.nix;

            packages = {
              inherit (pkgs.patchedPackages) gitlab-runner;
            };

            checks =
              let
                devShells = lib.mapAttrs' (n: lib.nameValuePair "devShell-${n}") self'.devShells;
                # nixosConfigurations = lib.mapAttrs' (
                #   n: v: lib.nameValuePair "nixosConfigurations-${n}" v.config.system.build.toplevel
                # ) ((lib.filterAttrs (_: v: v.pkgs.stdenv.hostPlatform.system == system)) self.nixosConfigurations);
                nixosConfigurations = { };
                packages = lib.mapAttrs' (n: lib.nameValuePair "package-${n}") self'.packages;
                custom = {
                  reuse =
                    let
                      files = pkgs.nix-gitignore.gitignoreSourcePure [ ] (pkgs.lib.cleanSource ./.);
                    in
                    pkgs.runCommandLocal "reuse" { } ''
                      ${pkgs.lib.getExe pkgs.reuse} --root ${files} lint | tee $out
                    '';
                };
              in
              devShells // nixosConfigurations // packages // custom;
          };
      });
}
