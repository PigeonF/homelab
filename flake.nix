{
  description = "Nix configurations for my homelab";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=refs/heads/release-25.11";
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
      inputs.flake-parts.follows = "flake-parts";
      inputs.home-manager.follows = "home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
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
      url = "github:nix-community/home-manager?ref=refs/heads/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "github:nix-community/impermanence?ref=refs/heads/master";
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
          ./hosts/hl-ci-x-01
          ./hosts/hl-dev-x-01
          ./hosts/hl-dev-x-02
          ./hosts/hl-vhost-x-01
          ./installer
          ./nix/flake-modules/deploy-rs.nix
        ];

        flake = { };

        perSystem =
          { pkgs, ... }:
          {
            treefmt = import ./treefmt.nix;

            checks = {
              reuse =
                let
                  files = pkgs.nix-gitignore.gitignoreSourcePure [ ] (pkgs.lib.cleanSource ./.);
                in
                pkgs.runCommandLocal "reuse" { } ''
                  ${pkgs.lib.getExe pkgs.reuse} --root ${files} lint | tee $out
                '';
            };
          };
      });
}
