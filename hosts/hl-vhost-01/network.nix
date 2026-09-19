{
  config = {
    services = {
      resolved = {
        settings = {
          Resolve = {
            MulticastDNS = true;
          };
        };
      };
    };
    systemd = {
      network = {
        enable = true;
        netdevs = {
          "30-br171" = {
            netdevConfig = {
              Kind = "bridge";
              Name = "br171";
            };
          };
        };
        networks = {
          "30-enp170s0" = {
            matchConfig = {
              Name = "enp170s0";
              Type = "ether";
            };
            networkConfig = {
              MulticastDNS = "yes";
              DHCP = "yes";
              UseDomains = "yes";
              IPv6PrivacyExtensions = "kernel";
            };
          };
          "30-enp171s0" = {
            matchConfig = {
              Name = "enp171s0";
              Type = "ether";
            };
            networkConfig = {
              Bridge = "br171";
            };
            linkConfig = {
              RequiredForOnline = "enslaved";
            };
          };
          "30-wlp172s0" = {
            matchConfig = {
              Name = "wlp172s0";
            };
            linkConfig = {
              Unmanaged = "yes";
            };
          };
          "40-br171" = {
            matchConfig = {
              Name = "br171";
              Type = "bridge";
            };
            networkConfig = {
              LinkLocalAddressing = "no";
              IPv6AcceptRA = false;
              ConfigureWithoutCarrier = true;
            };
            linkConfig = {
              RequiredForOnline = "no";
            };
          };
        };
        wait-online = {
          # TODO(PigeonF): See if we can remove this
          anyInterface = true;
        };
      };
    };
  };
}
