{ ... }:
let
  zpool = "zroot";
in
{
  disko = {
    devices = {
      disk = {
        ssd = {
          type = "disk";
          device = "/dev/disk/by-id/nvme-CT1000P3PSSD8_25144F7234A9";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                size = "550M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };
              zfs = {
                size = "100%";
                content = {
                  type = "zfs";
                  pool = zpool;
                };
              };
            };
          };
        };
      };
      zpool = {
        "${zpool}" = {
          type = "zpool";
          options = {
            ashift = "12";
            autotrim = "on";
          };
          rootFsOptions = {
            acltype = "posixacl";
            canmount = "off";
            "com.sun:auto-snapshot" = "false";
            compression = "zstd";
            dnodesize = "auto";
            mountpoint = "none";
            normalization = "formD";
            relatime = "on";
            xattr = "sa";
          };
          datasets = {
            "local" = {
              type = "zfs_fs";
              options.mountpoint = "none";
            };
            "local/home" = {
              type = "zfs_fs";
              mountpoint = "/home";
              options."com.sun:auto-snapshot" = "true";
            };
            "local/nix" = {
              type = "zfs_fs";
              mountpoint = "/nix";
              options."com.sun:auto-snapshot" = "false";
            };
            "local/root" = {
              type = "zfs_fs";
              mountpoint = "/";
              options."com.sun:auto-snapshot" = "false";
            };
          };
        };
      };
    };
  };
}
