{
  self,
  pkgs,
  ...
}:
let
  homelab = self;
in
{
  imports = [
    homelab.nixosModules.mixins-common
    homelab.nixosModules.mixins-docker
    homelab.nixosModules.mixins-environment
    homelab.nixosModules.mixins-networking
    homelab.nixosModules.mixins-nix
    homelab.nixosModules.mixins-openssh
    homelab.nixosModules.profiles-nspawn
  ];

  environment = {
    systemPackages = [ pkgs.socat ];
  };

  networking = {
    hostId = "5eeea9df";
    hostName = "hl-dev-x-01";
  };

  nixpkgs = {
    hostPlatform = "x86_64-linux";
  };

  security = {
    sudo = {
      wheelNeedsPassword = false;
    };
  };

  system = {
    stateVersion = "25.11";
  };

  users = {
    users = {
      developer = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "docker"
        ];
        openssh = {
          authorizedKeys = {
            keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGs63WIkcWBEVHzc9Evjt/57Ikf9WPD1u7oFQVMO7e2a"
            ];
          };
        };
      };
    };
  };
}
