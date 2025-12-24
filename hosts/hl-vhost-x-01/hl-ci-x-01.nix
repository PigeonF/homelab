_: {
  systemd = {
    nspawn = {
      "hl-ci-x-01" = {
        execConfig = {
          Boot = true;
          #DropCabaility
          #NoNewPrivileges
          PrivateUsers = "pick";
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
        };
        unitConfig = {
          ConditionPathExists = "/var/lib/machines/hl-ci-x-01";
        };
        wantedBy = [ "machines.target" ];
        overrideStrategy = "asDropin";
      };
    };
  };
}
