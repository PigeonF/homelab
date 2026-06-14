{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  useLix = false; # TODO(PigeonF): Investigate why deploy fails when nix-daemon is not running
  lixPackageSet = pkgs: pkgs.lixPackageSets.latest;
  inherit (inputs)
    nixpkgs
    nixpkgs-unstable
    ;
in
{
  nixpkgs = {
    overlays = lib.optional useLix (
      final: _prev: {
        inherit (lixPackageSet final)
          colmena
          nix-direnv
          nix-eval-jobs
          nix-fast-build
          nixpkgs-review
          ;
      }
    );
  };
  nix = {
    channel = {
      enable = false;
    };
    daemonCPUSchedPolicy = "batch";
    daemonIOSchedClass = "idle";
    daemonIOSchedPriority = 7;
    optimise = {
      automatic = !config.boot.isContainer;
    };
    package = lib.mkIf useLix (lixPackageSet pkgs).lix;
    registry = {
      nixpkgs = {
        flake = nixpkgs;
      };
      nixpkgs-unstable = {
        flake = nixpkgs-unstable;
      };
    };
    settings = {
      # nspawn containers do not have enough UIDs assigned for this to work.
      # https://git.lix.systems/lix-project/lix/issues/387#issuecomment-16134
      auto-allocate-uids = !config.boot.isNspawnContainer;
      # download-buffer-size = 512 * 1024 * 1024;
      extra-experimental-features = [
        "auto-allocate-uids"
        "cgroups"
        "flakes"
        "nix-command"
      ];
      sandbox = true;
      system-features = [ "uid-range" ];
      trusted-users = [ "@wheel" ];
      use-cgroups = !config.boot.isNspawnContainer;
      use-xdg-base-directories = true;
    };
  };
  systemd = {
    services = {
      nix-daemon = {
        serviceConfig = {
          OOMScoreAdjust = 250;
        };
      };
      nix-gc = {
        serviceConfig = {
          CPUSchedulingPolicy = "batch";
          IOSchedulingClass = "idle";
          IOSchedulingPriority = 7;
        };
      };
    };
  };
}
