{
  systemd = {
    network = {
      enable = true;
      netdevs = {
        "30-br0" = {
          netdevConfig = {
            Description = "Bridge device used by nspawn containers to connect to the homelab network";
            Name = "br0";
            Kind = "bridge";
          };
        };
      };
      networks = {
        "40-enp170s0" = {
          matchConfig = {
            Name = "enp170s0";
          };
          networkConfig = {
            Bridge = "br0";
          };
          linkConfig = {
            RequiredForOnline = "enslaved";
          };
        };
        "40-enp171s0" = {
          matchConfig = {
            Name = "enp171s0";
          };
          networkConfig = {
            MulticastDNS = "yes";
            DHCP = "yes";
            UseDomains = "yes";
            IPv6PrivacyExtensions = "kernel";
          };
          linkConfig = {
            RequiredForOnline = "yes";
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
        "50-br0" = {
          matchConfig = {
            Name = "br0";
          };
          networkConfig = {
            MulticastDNS = "yes";
            DHCP = "yes";
            UseDomains = "yes";
            IPv6PrivacyExtensions = "kernel";
          };
        };
      };
    };
  };
}
