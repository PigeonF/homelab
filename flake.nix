{
  description = "Nix configurations for my homelab";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=refs/heads/release-25.05";
    systems.url = "github:nix-systems/default?ref=refs/heads/main";
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

        imports = [ ];

        flake = { };

        perSystem = { };
      });
}
