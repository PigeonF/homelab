{
  lib,
  inputs,
  ...
}:
let
  hl-dev-x-01 = lib.nixosSystem {
    specialArgs = inputs;
    modules = [
      ./configuration.nix
    ];
  };
in
{
  _file = ./default.nix;

  deploy-rs = {
    nodes = {
      hl-dev-x-01 = {
        hostname = "hl-dev-x-01";
        profilesOrder = [
          "system"
        ];
        profiles = {
          system = {
            user = "root";
            sshUser = "developer";
            path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos hl-dev-x-01;
          };
        };
      };
    };
  };

  flake = {
    nixosConfigurations = {
      inherit hl-dev-x-01;
    };
  };

  perSystem =
    { pkgs, ... }:
    {
      packages = rec {
        alpine-enter-chroot = pkgs.writeShellApplication {
          name = "enter-chroot";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.socat
          ];
          text = builtins.readFile ./enter-chroot.bash;
          bashOptions = [ ];
        };
        alpine-install-chroot = pkgs.writeShellApplication {
          name = "alpine-install-chroot";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.curl
          ];
          text = builtins.readFile ./chroot-install.bash;
          bashOptions = [ ];
          runtimeEnv = {
            ENTER_CHROOT_SCRIPT = lib.getExe alpine-enter-chroot;
          };
        };
      };
    };
}
