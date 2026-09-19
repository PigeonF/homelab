{
  disko,
  ...
}:
{
  imports = [
    disko.nixosModules.disko
  ];

  config = {
    disko = {
      devices = {
        disk = {
          builtin-ssd = {
            type = "disk";
            device = "/dev/disk/by-id/nvme-CT1000P3PSSD8_25144F7234A9";
            imageSize = "96G";
            content = {
              type = "gpt";
              partitions = {
                ESP = {
                  label = "boot";
                  size = "1G";
                  type = "EF00";
                  content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/boot";
                    mountOptions = [ "umask=0077" ];
                  };
                };
                luks = {
                  end = "-48G";
                  content = {
                    type = "luks";
                    name = "cryptdisk1";
                    settings = {
                      allowDiscards = true;
                      crypttabExtraOpts = [
                        "fido2-device=auto"
                        "token-timeout=30"
                      ];
                    };
                    content = {
                      type = "lvm_pv";
                      vg = "pool";
                    };
                  };
                };
                cryptswap = {
                  size = "32G";
                  content = {
                    type = "swap";
                    randomEncryption = true;
                    priority = 100;
                  };
                };
                hibernateswap = {
                  size = "16G";
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
        lvm_vg = {
          pool = {
            type = "lvm_vg";
            lvs = {
              btrfs = {
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = [
                    "-f"
                    "-L"
                    "nixos"
                  ];
                  postCreateHook = ''
                    MNTPOINT=$(mktemp -d)
                    mount "/dev/mapper/pool-btrfs" "$MNTPOINT" -o subvol=/
                    trap 'umount "$MNTPOINT"; rm -rf "$MNTPOINT"' EXIT
                    btrfs subvolume snapshot -r "$MNTPOINT/" "$MNTPOINT/rootfs-blank"
                  '';
                  postMountHook = ''
                    mkdir -p /mnt/persist/boot/etc/ssh/
                    if [ ! -f /mnt/persist/boot/etc/ssh/ssh_host_rsa_key ]; then
                      ssh-keygen -t rsa -N "" -f /mnt/persist/boot/etc/ssh/ssh_host_rsa_key
                    fi
                    if [ ! -f /mnt/persist/boot/etc/ssh/ssh_host_ed25519_key ]; then
                      ssh-keygen -t ed25519 -N "" -f /mnt/persist/boot/etc/ssh/ssh_host_ed25519_key
                    fi
                  '';
                  subvolumes = {
                    "/" = {
                      mountpoint = "/";
                      mountOptions = [
                        "compress=zstd"
                        "ssd"
                        "noatime"
                      ];
                    };
                    "/root" = {
                      mountpoint = "/root";
                      mountOptions = [
                        "compress=zstd"
                        "ssd"
                        "noatime"
                      ];
                    };
                    "/home" = {
                      mountpoint = "/home";
                      mountOptions = [
                        "compress=zstd"
                        "ssd"
                        "noatime"
                      ];
                    };
                    "/persist" = {
                      mountpoint = "/persist";
                      mountOptions = [
                        "compress=zstd"
                        "ssd"
                        "noatime"
                      ];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "compress=zstd"
                        "ssd"
                        "noatime"
                      ];
                    };
                    "/var/log" = {
                      mountpoint = "/var/log";
                      mountOptions = [
                        "compress=zstd"
                        "ssd"
                        "noatime"
                      ];
                    };
                    "/var/lib" = {
                      mountpoint = "/var/lib";
                      mountOptions = [
                        "compress=zstd"
                        "ssd"
                        "noatime"
                      ];
                    };
                    "/var/lib/containers" = {
                      mountpoint = "/var/lib/containers";
                      mountOptions = [
                        "compress=zstd"
                        "ssd"
                        "noatime"
                      ];
                    };
                    "/var/lib/machines" = {
                      mountpoint = "/var/lib/machines";
                      mountOptions = [
                        "compress=zstd"
                        "ssd"
                        "noatime"
                      ];
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
