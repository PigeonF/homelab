{ lib, ... }:
{
  config = {
    boot = {
      initrd = {
        enable = lib.mkDefault false;
      };
      loader = {
        grub = {
          enable = lib.mkDefault false;
        };
      };
    };
  };
}
