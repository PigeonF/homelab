{
  config = {
    homelab = {
      nspawn = {
        containers = {
          "hl-dev-01" = {
            docker = true;
          };
        };
      };
    };
    systemd = {
      network = {
        networks = {
          "50-nspawn-vb-hl-dev-01" = {
            matchConfig = {
              Name = "vb-hl-dev-01";
              Kind = "veth";
            };

            networkConfig = {
              Bridge = "br171";
            };
          };
        };
      };
      nspawn' = {
        "hl-dev-01" = {
          settings = {
            Exec = {
              NoNewPrivileges = false; # Enable `sudo`
            };
            Network = {
              Bridge = "br171";
            };
          };
        };
      };
    };
  };
}
