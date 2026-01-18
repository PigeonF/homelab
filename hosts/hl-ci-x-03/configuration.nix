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

  networking = {
    hostId = "f2f10ce4";
    hostName = "hl-ci-x-03";
  };

  nixpkgs = {
    hostPlatform = "x86_64-linux";
  };

  services = {
    gitlab-runner = {
      enable = true;
      clear-docker-cache = {
        enable = true;
        dates = "Mon,Wed,Fri";
      };
      package = pkgs.patchedPackages.gitlab-runner;
      gracefulTermination = true;
      gracefulTimeout = "30s";
      settings = {
        concurrent = 8;
      };
      services = {
        docker = {
          authenticationTokenConfigFile = "/run/host/credentials/auth-config-docker";
          dockerImage = "docker.io/busybox:latest";
          executor = "docker";
          registrationFlags = [
            "--docker-pull-policy if-not-present"
            "--docker-pull-policy if-not-present"
            "--docker-volumes /builds"
            "--docker-volumes /cache"
            "--docker-volumes /var/lib/containers/cache"
            # https://gitlab.com/gitlab-org/gitlab-runner/-/issues/4748
            "--docker-services-cap-add SYS_ADMIN"
            # TODO(PigeonF): Adjust default docker seccomp filter to allow @keyring
            "--docker-services-security-opt seccomp:unconfined"
            "--env FF_NETWORK_PER_BUILD=true"
            "--env FF_SCRIPT_SECTIONS=true"
            "--env FF_ADAPTIVE_REQUEST_CONCURRENCY=true"
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
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHlkgDzLhXjmncL47IiLRO5GfHqnEBhAv7AJOqiC51Nh"
            ];
          };
        };
      };
    };
  };
}
