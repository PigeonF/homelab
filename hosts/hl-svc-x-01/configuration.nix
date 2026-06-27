{
  homelabModulesPath,
  modulesPath,
  lib,
  config,
  ...
}:
{
  imports = [
    (homelabModulesPath + "/profiles/base.nix")
    (homelabModulesPath + "/virtualisation/nspawn-image.nix")
    (modulesPath + "/profiles/headless.nix")
    (modulesPath + "/profiles/perlless.nix")
  ];
  config = {
    image.modules.lxc = {
      config = {
        image = {
          baseName = "hl-svc-x-01";
        };
        systemd = {
          enableStrictShellChecks = false;
        };
      };
    };
    networking = {
      hostId = "1d11a4b1";
      hostName = "hl-svc-x-01";

      firewall = {
        allowedTCPPorts = [
          80
          443
        ];
      };
    };
    nixpkgs = {
      hostPlatform = "x86_64-linux";
    };
    services = {
      dockerRegistry = {
        enable = true;
        enableGarbageCollect = true;
        enableDelete = true;
      };
      traefik = {
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
        dynamicConfigOptions =
          let
            host = "fierlings.family";
          in
          {
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
    system = {
      disableInstallerTools = false;
      etc = {
        overlay = {
          # Gives a permission issue when run with restricted permissions
          enable = false;
        };
      };
      forbiddenDependenciesRegexes = lib.mkForce [ ];
      stateVersion = "26.05";
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
    time = {
      timeZone = "UTC";
    };
    users = {
      users = {
        root = {
          openssh = {
            authorizedKeys = {
              keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIkIUH48L+q7be2DHG94q59YNjPQ5SjD/Tye3mHvk0f+"
              ];
            };
          };
        };
      };
    };
    virtualisation = {
      diskSize =
        64 * 1024 # MiB
      ;
      docker = {
        enable = true;
      };
    };
  };
}
