{
  self,
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

  networking = {
    hostId = "88b542fd";
    hostName = "hl-ci-x-02";
  };

  nixpkgs = {
    hostPlatform = "x86_64-linux";
  };

  services = {
    gitlab-runner = {
      enable = true;
      clear-docker-cache = {
        enable = true;
      };
      gracefulTermination = true;
      gracefulTimeout = "30s";
      settings = {
        concurrent = 8;
      };
      services = {
        docker = {
          authenticationTokenConfigFile = "/run/host/credentials/gitlab-runner-auth-config-docker";
          dockerImage = "docker.io/busybox:latest";
          executor = "docker";
          registrationFlags = [
            "--docker-pull-policy if-not-present"
            "--docker-volumes /builds"
            "--docker-volumes /cache"
            "--docker-volumes /var/lib/containers"
            "--env FF_NETWORK_PER_BUILD=true"
            "--env FF_SCRIPT_SECTIONS=true"
          ];
        };
      };
    };
  };

  system = {
    stateVersion = "25.11";
    disableInstallerTools = true;
  };

  users = {
    users = {
      root = {
        openssh = {
          authorizedKeys = {
            keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC9mRJO18hlbFWTOHMKUofE1BWvBsiHjbNhOwu5aCfcU"
            ];
          };
        };
      };
    };
  };
}
