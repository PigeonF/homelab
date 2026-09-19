{ lib, ... }:
{
  services = {
    userborn = {
      enable = true;
    };
  };
  system = {
    disableInstallerTools = lib.mkDefault true;
    switch = {
      enable = lib.mkDefault false;
    };
    tools = {
      nixos-enter = {
        enable = lib.mkDefault false;
      };
      nixos-generate-config = {
        enable = lib.mkDefault false;
      };
      nixos-install = {
        enable = lib.mkDefault false;
      };
      nixos-option = {
        enable = lib.mkDefault false;
      };
    };
  };
  users = {
    mutableUsers = false;
  };
}
