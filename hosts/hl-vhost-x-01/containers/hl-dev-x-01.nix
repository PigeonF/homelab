{
  systemd = {
    nspawn = {
      "hl-dev-x-01" = {
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
      "systemd-nspawn@hl-dev-x-01" = {
        unitConfig = {
          ConditionPathExists = "/var/lib/machines/hl-dev-x-01";
        };
        wantedBy = [ "machines.target" ];
        overrideStrategy = "asDropin";
      };
    };
  };
}
