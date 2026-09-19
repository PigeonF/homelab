{ config, ... }:
{
  config = {
    sops = {
      secrets = {
        "hl-ci-02/gitlab-runner/auth-config-cross" = {
          restartUnits = [ "systemd-nspawn@hl-ci-02.service" ];
        };
        "hl-ci-02/gitlab-runner/auth-config-docker" = {
          restartUnits = [ "systemd-nspawn@hl-ci-02.service" ];
        };
        "hl-ci-02/gitlab-runner/auth-config-plain" = {
          restartUnits = [ "systemd-nspawn@hl-ci-02.service" ];
        };
      };
    };
    homelab = {
      nspawn = {
        containers = {
          "hl-ci-02" = {
            docker = true;
            ephemeral = true;
            credentials = {
              "auth-config-cross" = config.sops.secrets."hl-ci-02/gitlab-runner/auth-config-cross".path;
              "auth-config-docker" = config.sops.secrets."hl-ci-02/gitlab-runner/auth-config-docker".path;
              "auth-config-plain" = config.sops.secrets."hl-ci-02/gitlab-runner/auth-config-plain".path;
            };
          };
        };
      };
    };
    systemd = {
      services = {
        "systemd-nspawn@hl-ci-02" = {
          serviceConfig = {
            CPUQuota = "200%";
            MemoryHigh = "6G";
            MemoryMax = "8G";
          };
          unitConfig = {
            After = [ "sops-nix.service" ];
          };
        };
      };
    };
  };
}
