{ lib, ... }:
{
  config = {
    services = {
      openssh = {
        enable = lib.mkOverride 99 false;
      };
    };
    users = {
      allowNoPasswordLogin = lib.mkDefault true;
    };
  };
}
