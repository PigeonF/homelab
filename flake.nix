{
  description = "Nix configurations for my homelab";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=refs/heads/release-25.05";
    systems.url = "github:nix-systems/default?ref=refs/heads/main";

    deploy-rs = {
      url = "github:serokell/deploy-rs?ref=refs/heads/master";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "flake-utils";
    };
    disko = {
      url = "github:nix-community/disko?ref=refs/heads/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts?ref=refs/heads/main";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    flake-utils = {
      url = "github:numtide/flake-utils?ref=refs/heads/main";
      inputs.systems.follows = "systems";
    };
    impermanence = {
      url = "github:nix-community/impermanence?ref=refs/heads/master";
    };
    nixos-facter-modules = {
      url = "github:nix-community/nixos-facter-modules?ref=refs/heads/main";
    };
  };

  outputs =
    inputs@{
      flake-parts,
      systems,
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
          ./hosts/hl-dev-x-01
          ./hosts/hl-vhost-x-01
          ./installer
          ./nix/modules/deploy-rs.nix
        ];

        flake = { };

        perSystem = { };
      });
}
