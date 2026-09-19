{
  homelabModulesPath,
  config,
  ...
}:
{
  imports = [
    (homelabModulesPath + "/profiles/docker.nix")
    (homelabModulesPath + "/profiles/hardening.nix")
    (homelabModulesPath + "/profiles/server.nix")
    (homelabModulesPath + "/profiles/systemd-machine.nix")
    (homelabModulesPath + "/profiles/systemd-networking.nix")
    ./users/root.nix
  ];

  config = {
    homelab = {
      network = {
        requireIPv4 = true; # gitlab-runner requires an IPv4 address for gitlab.com
      };
    };

    networking = {
      hostId = "49e91848";
      hostName = "hl-svc-01";
      firewall = {
        allowedTCPPorts = [
          80
          443
        ];
      };
    };

    system = {
      stateVersion = "26.05";
    };

    services = {
      dockerRegistry = {
        enable = true;
        enableGarbageCollect = true;
        enableDelete = true;
      };
      traefik =
        let
          host = "fierlings.family";
        in
        {
          enable = true;
          environmentFiles = [ "/run/host/credentials/traefik-acme" ];
          staticConfigOptions = {
            api = {
              dashboard = true;
            };
            entryPoints = {
              http = {
                address = ":80";
                asDefault = true;
                http = {
                  redirections = {
                    entrypoint = {
                      to = "https";
                      scheme = "https";
                    };
                  };
                };
              };
              https = {
                address = ":443";
                asDefault = true;
                http = {
                  tls = {
                    certResolver = "letsencrypt";
                    domains = [
                      {
                        main = host;
                        sans = [ "*.${host}" ];
                      }
                    ];
                  };
                };
              };
            };
            global = {
              checkNewVersion = false;
            };
            log = {
              level = "INFO";
              filePath = "${config.services.traefik.dataDir}/traefik.log";
              format = "json";
            };
            certificatesResolvers = {
              letsencrypt = {
                acme = {
                  email = "jonas.fierlings+acme@gmail.com";
                  storage = "${config.services.traefik.dataDir}/acme.json";
                  dnschallenge = {
                    provider = "cloudflare";
                    resolvers = [
                      "1.1.1.1:53"
                      "8.8.8.8:53"
                    ];
                  };
                };
              };
            };
          };
          dynamicConfigOptions = {
            http = {
              services = {
                registry = {
                  loadBalancer = {
                    servers = [
                      {
                        url = "http://${config.services.dockerRegistry.listenAddress}:${toString config.services.dockerRegistry.port}";
                      }
                    ];
                  };
                };
              };
              routers = {
                dashboard = {
                  entryPoints = [ "https" ];
                  rule = "Host(`traefik.${host}`)";
                  service = "api@internal";
                };
                registry = {
                  entryPoints = [ "https" ];
                  rule = "Host(`registry.${host}`)";
                  service = "registry";
                };
              };
            };
          };
        };
    };

    systemd = {
      services = {
        docker-registry = {
          environment = {
            OTEL_TRACES_EXPORTER = "none";
          };
        };

        traefik = {
          serviceConfig = {
            Environment = [
              "LEGO_DISABLE_CNAME_SUPPORT=true"
            ];
          };
        };
      };
    };
  };
}
