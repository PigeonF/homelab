{ lib, ... }:
{
  options = {
    homelab = {
      systemd-machine = {
        limit = lib.mkOption {
          type = lib.types.str;
          default = "none";
        };
      };
    };
  };
  config = {
    # systemd machines usually don't have boot or filesystem related settings
    # (they are just a directory on the host).
    # Use config.system.build.images.{nspawn,vmspawn} instead of a "normal"
    # build.
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
