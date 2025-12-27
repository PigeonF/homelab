{ config, ... }:
{
  sops = {
    secrets = {
      "hl-ci-x-01/gitlab-runner/auth-config-docker" = {
        sopsFile = ../secrets/hl-ci-x-01.yaml;
        key = "gitlab-runner/auth-config-docker";
        restartUnits = [ "systemd-nspawn@hl-ci-x-01.service" ];
      };
    };
  };
  systemd = {
    nspawn = {
      "hl-ci-x-01" = {
        execConfig = {
          Boot = true;
          NoNewPrivileges = true;
          PrivateUsers = "pick";
          # For docker
          Capability = "CAP_SETUID CAP_SETGID";
          SystemCallFilter = "@keyring bpf";
          LinkJournal = "try-guest";
          Timezone = "off";
        };
        filesConfig = {
          PrivateUsersOwnership = "auto";
          Bind = [
            "/sys:/run/sys"
          ];
        };
        networkConfig = {
          Private = true;
          VirtualEthernet = true;
          Bridge = "br0";
        };
      };
    };
    services = {
      "systemd-nspawn@hl-ci-x-01" = {
        serviceConfig = {
          CPUQuota = "400%";
          MemoryHigh = "8G";
          MemoryMax = "12G";
          LoadCredential = "auth-config-docker:${
            config.sops.secrets."hl-ci-x-01/gitlab-runner/auth-config-docker".path
          }";
          ExecStart = [
            ""
            "systemd-nspawn --keep-unit --settings=override --machine=%i --load-credential=gitlab-runner-auth-config-docker:auth-config-docker"
          ];
        };
        unitConfig = {
          After = [ "sops-nix.service" ];
          ConditionPathExists = "/var/lib/machines/hl-ci-x-01";
        };
        wantedBy = [ "machines.target" ];
        overrideStrategy = "asDropin";
      };
    };
  };
}
