{ config, ... }:
{
  config = {
    sops = {
      secrets = {
        "hl-svc-01/traefik/acme" = {
          restartUnits = [ "systemd-nspawn@hl-svc-01.service" ];
        };
      };
    };
    homelab = {
      nspawn = {
        containers = {
          "hl-svc-01" = {
            docker = true;
            credentials = {
              "traefik-acme" = config.sops.secrets."hl-svc-01/traefik/acme".path;
            };
          };
        };
      };
    };
    systemd = {
      network = {
        networks = {
          "50-nspawn-vb-hl-svc-01" = {
            matchConfig = {
              Name = "vb-hl-svc-01";
              Kind = "veth";
            };

            networkConfig = {
              Bridge = "br171";
            };
          };
        };
      };
      nspawn' = {
        "hl-svc-01" = {
          settings = {
            Network = {
              Bridge = "br171";
            };
          };
        };
      };
      services = {
        "systemd-nspawn@hl-svc-01" = {
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
