{
  homelabModulesPath,
  pkgs,
  ...
}:
{
  imports = [
    (homelabModulesPath + "/profiles/gitlab-ci-runner.nix")
  ];
  networking = {
    hostId = "f5f36ce7";
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
        request_concurrency = 4;
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
            "--env FF_USE_INIT_WITH_DOCKER_EXECUTOR=true"
            "--env FF_USE_NEW_BASH_EVAL_STRATEGY=true"
          ];
        };
      };
    };
  };
  system = {
    stateVersion = "26.05";
  };
  virtualisation = {
    diskSize =
      32 * 1024 # MiB
    ;
  };
}
