{
  systemd = {
    network = {
      enable = true;
      netdevs = {
        "30-br-public" = {
          netdevConfig = {
            Description = "Bridge used for nspawn containers that are reachable from the network";
            Name = "br-public";
            Kind = "bridge";
          };
        };
      };
      networks = {
        "40-enp170s0" = {
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
        "40-enp171s0" = {
          matchConfig = {
            Name = "enp171s0";
            Type = "ether";
          };
          networkConfig = {
            Bridge = "br-public";
          };
          linkConfig = {
            RequiredForOnline = "enslaved";
          };
        };
        "40-wlp172s0" = {
          matchConfig = {
            Name = "wlp172s0";
          };
          linkConfig = {
            Unmanaged = "yes";
          };
        };
        "50-br-public" = {
          matchConfig = {
            Name = "br-public";
          };
        };
      };
    };
  };
}
