{
  pkgs,
  impermanence,
  ...
}:
{
  imports = [
    impermanence.nixosModules.impermanence
  ];

  config = {
    boot = {
      initrd = {
        network = {
          ssh = {
            hostKeys = [
              "/persist/boot/etc/ssh/ssh_host_ed25519_key"
              "/persist/boot/etc/ssh/ssh_host_rsa_key"
            ];
          };
        };
        systemd = {
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
  };
}
