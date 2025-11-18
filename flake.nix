{
  description = "Nix configurations for my homelab";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=refs/heads/staging-25.11";
    systems.url = "github:nix-systems/default?ref=refs/heads/main";

    disko = {
      url = "github:nix-community/disko?ref=refs/heads/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts?ref=refs/heads/main";
      inputs.nixpkgs-lib.follows = "nixpkgs";
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
          ./installer
          ./hosts/hl-vhost-x-01
        ];

        flake = { };

        perSystem = { };
      });
}
