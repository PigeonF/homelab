_: {
  systemd = {
    nspawn = {
      "hl-dev-x-02" = {
        execConfig = {
          Boot = true;
          Ephemeral = true;
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
      "systemd-nspawn@hl-dev-x-02" = {
        unitConfig = {
          ConditionPathExists = "/var/lib/machines/hl-dev-x-02";
        };
        # Start this container on demand
        # wantedBy = [ "machines.target" ];
        overrideStrategy = "asDropin";
      };
    };
  };
}
