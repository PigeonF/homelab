{ pkgs, ... }:
let
  zpool = "zroot";
  rootVolume = "local/root";
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
                end = "-48G";
                content = {
                  type = "zfs";
                  pool = zpool;
                };
              };
              swap = {
                size = "100%";
                content = {
                  type = "swap";
                  discardPolicy = "both";
                  resumeDevice = true;
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
            "local/incus" = {
              type = "zfs_fs";
              options.mountpoint = "none";
            };
            "local/nix" = {
              type = "zfs_fs";
              mountpoint = "/nix";
              options."com.sun:auto-snapshot" = "false";
            };
            "local/persist" = {
              type = "zfs_fs";
              mountpoint = "/persist";
              options."com.sun:auto-snapshot" = "false";
            };
            "${rootVolume}" = {
              type = "zfs_fs";
              mountpoint = "/";
              postCreateHook = "zfs snapshot ${zpool}/${rootVolume}@start";
              options."com.sun:auto-snapshot" = "false";
            };
          };
        };
      };
    };
  };

  boot = {
    initrd = {
      systemd = {
        services = {
          initrd-rollback-root = {
            after = [ "zfs-import-${zpool}.service" ];
            wantedBy = [ "initrd.target" ];
            before = [
              "sysroot.mount"
            ];
            path = [ pkgs.zfs ];
            description = "Rollback root fs";
            unitConfig.DefaultDependencies = "no";
            serviceConfig.Type = "oneshot";
            script = "zfs rollback -r ${zpool}/${rootVolume}@start && echo 'zfs rollback complete'";
          };
        };
      };
    };
  };

  environment = {
    persistence = {
      "/persist" = {
        hideMounts = true;
        directories = [
          "/var/log"
          "/var/lib"
        ];
        files = [
          "/etc/machine-id"
        ];
      };
    };
  };

  fileSystems = {
    "/persist" = {
      neededForBoot = true;
    };
  };

  services = {
    openssh = {
      hostKeys = [
        {
          type = "ed25519";
          path = "/persist/etc/ssh/ssh_host_ed25519_key";
        }
        {
          type = "rsa";
          bits = 4096;
          path = "/persist/etc/ssh/ssh_host_rsa_key";
        }
      ];
    };
  };
}
