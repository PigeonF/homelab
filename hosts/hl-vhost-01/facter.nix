{ nixos-facter-modules, ... }:
{
  imports = [
    nixos-facter-modules.nixosModules.facter
  ];
  config = {
    facter = {
      detected = {
        bluetooth = {
          enable = false;
        };
        dhcp = {
          enable = false;
        };
      };
      reportPath = ./facter.json;
    };
  };
}
