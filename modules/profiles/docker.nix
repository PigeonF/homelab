{
  config,
  lib,
  pkgs,
  ...
}:
let
  hasNftables = config.networking.nftables.enable;
in
{
  systemd = {
    services = {
      docker = {
        path = lib.mkIf hasNftables [ pkgs.nftables ];
      };
    };
  };
  virtualisation = {
    docker = {
      enable = lib.mkDefault true;
      daemon = {
        settings = {
          firewall-backend = lib.mkIf hasNftables "nftables";
        };
      };
    };
  };
}
