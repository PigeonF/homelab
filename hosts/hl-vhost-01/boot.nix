{
  config,
  pkgs,
  ...
}:
{
  config = {
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
      loader = {
        efi = {
          canTouchEfiVariables = true;
        };
        grub = {
          enable = false;
        };
        systemd-boot = {
          enable = true;
        };
      };
      tmp = {
        cleanOnBoot = true;
      };
    };

    fileSystems = {
      "/var/log" = {
        neededForBoot = true;
      };
      "/var/lib" = {
        neededForBoot = true;
      };
    };
  };
}
