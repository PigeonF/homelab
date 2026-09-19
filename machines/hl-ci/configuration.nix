{
  config,
  homelabModulesPath,
  lib,
  pkgs,
  dotfiles,
  ...
}:
{
  imports = [
    (homelabModulesPath + "/profiles/docker.nix")
    (homelabModulesPath + "/profiles/egress-only.nix")
    (homelabModulesPath + "/profiles/hardening.nix")
    (homelabModulesPath + "/profiles/server.nix")
    (homelabModulesPath + "/profiles/systemd-machine-ephemeral.nix")
    (homelabModulesPath + "/profiles/systemd-machine.nix")
    (homelabModulesPath + "/profiles/systemd-networking.nix")
  ];

  options = {
    homelab = {
      hl-ci = {
        gitlab-runners = {
          defaultFlags = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "--docker-pull-policy if-not-present"
              "--docker-volumes /builds"
              "--docker-volumes /cache"
              "--env FF_NETWORK_PER_BUILD=true"
              "--env FF_SCRIPT_SECTIONS=true"
              "--env FF_USE_INIT_WITH_DOCKER_EXECUTOR=true"
              "--env FF_USE_NEW_BASH_EVAL_STRATEGY=true"
            ];
          };
          cross = {
            enable = lib.mkEnableOption "gitlab runner with cross compilation support";
            secret = lib.mkOption {
              type = lib.types.str;
              default = "auth-config-cross";
            };
          };
          docker = {
            enable = lib.mkEnableOption "gitlab runner with docker support";
            secret = lib.mkOption {
              type = lib.types.str;
              default = "auth-config-docker";
            };
          };
          plain = {
            enable = lib.mkEnableOption "plain gitlab runner";
            secret = lib.mkOption {
              type = lib.types.str;
              default = "auth-config-plain";
            };
          };
        };
      };
    };
  };

  config =
    let
      cfg = config.homelab.hl-ci;
    in
    {
      warnings = [
        (lib.mkIf (
          config.services.gitlab-runner.services == { }
        ) "hl-ci configuration without enabled gitlab runner services")
      ];

      homelab = {
        network = {
          requireIPv4 = true; # gitlab-runner requires an IPv4 address for gitlab.com
        };
      };

      nixpkgs = {
        overlays = [
          dotfiles.overlays.sdk-apple-darwin
          dotfiles.overlays.sdk-pc-windows-msvc
        ];
      };

      services = {
        gitlab-runner = {
          enable = config.services.gitlab-runner.services != { };
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
            cross = lib.mkIf cfg.gitlab-runners.cross.enable {
              authenticationTokenConfigFile = "/run/host/credentials/${cfg.gitlab-runners.cross.secret}";
              dockerImage = "docker.io/busybox:latest";
              executor = "docker";
              registrationFlags = cfg.gitlab-runners.defaultFlags ++ [
                "--docker-volumes ${pkgs.sdk-apple-darwin}:/opt/sdks/macosx:ro"
                "--docker-volumes ${pkgs.sdk-pc-windows-msvc}:/opt/sdks/msvc:ro"
              ];
            };
            docker = lib.mkIf cfg.gitlab-runners.docker.enable {
              authenticationTokenConfigFile = "/run/host/credentials/${cfg.gitlab-runners.docker.secret}";
              dockerImage = "docker.io/busybox:latest";
              executor = "docker";
              registrationFlags = cfg.gitlab-runners.defaultFlags ++ [
                # TODO(PigeonF): Figure out a way to drop this (e.g. different nspawn settings)
                "--docker-cap-add SYS_ADMIN"
                # https://gitlab.com/gitlab-org/gitlab-runner/-/issues/4748
                "--docker-services-cap-add SYS_ADMIN"
                # TODO(PigeonF): Adjust default docker seccomp filter to allow @keyring
                "--docker-services-security-opt seccomp:unconfined"
                "--docker-volumes /var/lib/containers/cache"
              ];
            };
            plain = lib.mkIf cfg.gitlab-runners.plain.enable {
              authenticationTokenConfigFile = "/run/host/credentials/${cfg.gitlab-runners.plain.secret}";
              dockerImage = "docker.io/busybox:latest";
              executor = "docker";
              registrationFlags = cfg.gitlab-runners.defaultFlags;
            };
          };
        };
      };

      system = {
        stateVersion = "26.05";
      };

      systemd = {
        services = {
          gitlab-runner = {
            after = [ "network-online.target" ];
            requires = [ "network-online.target" ];
          };
        };
      };
    };
}
