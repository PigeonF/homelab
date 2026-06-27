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
        cross = {
          authenticationTokenConfigFile = "/run/host/credentials/auth-config-cross";
          dockerImage = "docker.io/busybox:latest";
          executor = "docker";
          registrationFlags = [
            "--docker-pull-policy if-not-present"
            "--docker-volumes /builds"
            "--docker-volumes /cache"
            "--docker-volumes ${pkgs.sdk-apple-darwin}:/opt/sdks/macosx:ro"
            "--docker-volumes ${pkgs.sdk-pc-windows-msvc}:/opt/sdks/msvc:ro"
            "--env FF_NETWORK_PER_BUILD=true"
            "--env FF_SCRIPT_SECTIONS=true"
            "--env FF_USE_INIT_WITH_DOCKER_EXECUTOR=true"
            "--env FF_USE_NEW_BASH_EVAL_STRATEGY=true"
          ];
        };
        docker = {
          authenticationTokenConfigFile = "/run/host/credentials/auth-config-docker";
          dockerImage = "docker.io/busybox:latest";
          executor = "docker";
          registrationFlags = [
            # TODO(PigeonF): Figure out a way to drop this (e.g. different nspawn settings)
            "--docker-cap-add SYS_ADMIN"
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
      64 * 1024 # MiB
    ;
  };
}
