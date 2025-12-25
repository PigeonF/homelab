{
  config,
  pkgs,
  ...
}:
{
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
                  ls -la /mnt
                  ls -la /mnt/persist

                  test -d  /mnt/
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
                  "/var/lib/containers" = { };
                  "/var/lib/machines" = { };
                };
              };
            };
          };
        };
      };
    };
  };

  boot = {
    initrd = {
      availableKernelModules = [
        "aesni_intel"
        "cryptd"
        "r8169"
      ];
      network = {
        ssh = {
          enable = true;
          port = 2222;
          hostKeys = [
            "/persist/boot/etc/ssh/ssh_host_ed25519_key"
            "/persist/boot/etc/ssh/ssh_host_rsa_key"
          ];
          authorizedKeys =
            config.users.users.root.openssh.authorizedKeys.keys
            ++ config.users.users.administrator.openssh.authorizedKeys.keys;
        };
      };
      systemd = {
        enable = true;
        network = {
          enable = true;
          networks = {
            "10-ethernet" = {
              matchConfig = {
                Type = "ether";
              };
              networkConfig = {
                DHCP = true;
              };
            };
          };
        };
        services = {
          # btrfs-rollback = {
          #   description = "Rollback BTRFS root subvolume to a pristine state";
          #   wantedBy = [ "initrd.target" ];
          #   before = [ "sysroot.mount" ];
          #   requires = [ "dev-pool-btrfs.device" ];
          #   after = [ "dev-pool-btrfs.device" ];
          #   unitConfig = {
          #     DefaultDependencies = "no";
          #   };
          #   serviceConfig = {
          #     Type = "oneshot";
          #   };
          #   script = ''
          #     set -o errexit
          #     set -o nounset
          #     set -o pipefail

          #     MNTPOINT=/mnt
          #     mkdir -p "$MNTPOINT"
          #     trap 'umount "$MNTPOINT"; rm -rf "$MNTPOINT"' EXIT
          #     mount -o subvol=/ -t btrfs /dev/mapper/pool-btrfs "$MNTPOINT"
          #     btrfs subvolume list -o "$MNTPOINT/" | cut -f9 -d' ' | while read -r subvolume; do
          #       echo "deleting /$subvolume subvolume..."
          #       btrfs subvolume delete "$MNTPOINT/$subvolume"
          #     done
          #     echo "deleting /rootfs subvolume..."
          #     btrfs subvolume delete "$MNTPOINT/rootfs"
          #     echo "restoring blank /rootfs subvolume..."
          #     btrfs subvolume snapshot "$MNTPOINT/rootfs-blank" "$MNTPOINT/rootfs"
          #     umount "$MNTPOINT"
          #   '';
          # };
          remote-unlock = {
            description = "Prepare .profile for remote unlock";
            wantedBy = [ "initrd.target" ];
            after = [ "network-online.target" ];
            unitConfig = {
              DefaultDependencies = "no";
            };
            serviceConfig = {
              Type = "oneshot";
              StandardOutput = "console+journal";
            };
            script = ''
              mkdir -p /var/empty/
              echo "systemctl default" > /var/empty/.profile
            '';
          };
        };
        storePaths = [ pkgs.ncurses ];
        units = {
          "dev-pool-btrfs.device" = {
            overrideStrategy = "asDropin";
            text = ''
              [Unit]
              Requires=cryptsetup.target
              After=cryptsetup.target
            '';
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
          "/var/lib/nftables"
          "/var/lib/nixos"
          "/var/lib/private"
          "/var/lib/systemd"
        ];
        files = [
          "/etc/machine-id"
        ];
      };
    };
    systemPackages = [ pkgs.yubikey-manager ];
  };

  fileSystems = {
    "/persist" = {
      neededForBoot = true;
    };
    "/var/log" = {
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
