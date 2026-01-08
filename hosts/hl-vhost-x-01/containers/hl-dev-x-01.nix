{
  systemd = {
    nspawn = {
      "hl-dev-x-01" = {
        execConfig = {
          Boot = true;
          NoNewPrivileges = false;
          PrivateUsers =
            let
              start = 655356 * 10;
              # Need 1 for user, 2 for podman
              amount = 3;
            in
            "${toString start}:${toString (65536 * amount)}";
          # For docker and chroots
          Capability = "CAP_SETUID CAP_SETGID CAP_SYS_ADMIN";
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
