_: {
  systemd = {
    nspawn = {
      "hl-dev-x-01" = {
        execConfig = {
          Boot = true;
          #DropCabaility
          #NoNewPrivileges
          PrivateUsers = "pick";
          LinkJournal = "try-guest";
          Timezone = "off";
        };
        filesConfig = {
            PrivateUsersOwnership = "auto";
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
