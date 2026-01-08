# Configure the system networking
{
  config = {
    networking = {
      domain = "internal";
      firewall = {
        allowPing = true;
      };
      nftables = {
        enable = true;
      };
      useDHCP = false;
      useNetworkd = true;
    };
    services = {
      # firewalld = {
      #   enable = true;
      # };
      resolved = {
        enable = true;
        llmnr = "false";
        extraConfig = ''
          MulticastDNS=yes
        '';
      };
      timesyncd = {
        enable = true;
      };
    };
    systemd = {
      services = {
        systemd-networkd = {
          stopIfChanged = false;
        };
        systemd-resolved = {
          stopIfChanged = false;
        };
      };
      network = {
        enable = true;
        wait-online = {
          # TODO(PigeonF): See if we can remove this
          anyInterface = true;
        };
      };
    };
  };
}
