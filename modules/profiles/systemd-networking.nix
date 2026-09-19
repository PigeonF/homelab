{ config, lib, ... }:
{
  options = {
    homelab = {
      network = {
        requireIPv4 = lib.mkEnableOption "wait for IPv4 address to be assigned";
      };
    };
  };
  config =
    let
      cfg = config.homelab.network;
    in
    {
      networking = {
        useDHCP = lib.mkDefault false;
        useHostResolvConf = lib.mkIf config.boot.isNspawnContainer (lib.mkOverride 99 false);
        useNetworkd = lib.mkDefault true;
      };
      services = {
        resolved = {
          enable = lib.mkDefault true;
          settings = {
            Resolve = {
              LLMNR = lib.mkDefault "resolve";
              MulticastDNS = lib.mkDefault "resolve";
            };
          };
        };
        timesyncd = {
          enable = lib.mkDefault true;
        };
      };
      systemd = {
        network = {
          networks = {
            # Override systemd's 80-container-host0.network which uses DHCPv4.UseTimezone = yes,
            # even though nspawn likely does not have permissions to do so.
            "79-container-host0" = lib.mkIf config.boot.isNspawnContainer {
              matchConfig = {
                Kind = "veth";
                Name = "host0";
                Virtualization = "container";
              };
              networkConfig = {
                DHCP = "yes";
                LinkLocalAddressing = "yes";
                LLDP = "yes";
                EmitLLDP = "customer-bridge";
              };
              linkConfig = {
                RequiredForOnline = lib.mkIf cfg.requireIPv4 "routable";
                RequiredFamilyForOnline = lib.mkIf cfg.requireIPv4 "ipv4";
              };
              dhcpV4Config = {
                UseTimezone = "no";
              };
            };
            "80-container-macvlan" = lib.mkIf config.boot.isNspawnContainer {
              matchConfig = {
                Kind = "macvlan";
                Virtualization = "container";
              };
              networkConfig = {
                DHCP = "yes";
                LinkLocalAddressing = "yes";
                LLDP = "yes";
                EmitLLDP = "customer-bridge";
              };
              linkConfig = {
                RequiredForOnline = lib.mkIf cfg.requireIPv4 "routable";
                RequiredFamilyForOnline = lib.mkIf cfg.requireIPv4 "ipv4";
              };
              dhcpV4Config = {
                UseTimezone = "no";
              };
            };
          };
        };
        # Make sure changes to the networking config don't cause disconnects
        services = {
          systemd-networkd = {
            stopIfChanged = lib.mkDefault false;
          };
          systemd-resolved = {
            stopIfChanged = lib.mkDefault false;
          };
        };
      };
    };
}
