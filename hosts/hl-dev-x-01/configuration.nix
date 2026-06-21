{
  config,
  homelabModulesPath,
  pkgs,
  ...
}:
{
  imports = [
    (homelabModulesPath + "/profiles/base.nix")
    (homelabModulesPath + "/profiles/interactive.nix")
    (homelabModulesPath + "/virtualisation/nspawn-image.nix")
  ];
  documentation = {
    dev = {
      enable = true;
    };
    man = {
      man-db = {
        enable = false;
      };
      mandoc = {
        enable = true;
      };
    };
  };
  environment = {
    systemPackages = [
      pkgs.man-pages
      pkgs.man-pages-posix
      pkgs.socat
    ];
  };
  image.modules.lxc = {
    config = {
      image = {
        baseName = "hl-dev-x-01";
      };
      systemd = {
        enableStrictShellChecks = false;
      };
    };
  };
  # TODO(PigeonF): Currently does not work correctly at runtime because of mount
  # permission issues. Use lxc image instead and import-tar.
  image.modules.nspawn =
    { lib, ... }:
    {
      image = {
        repart = {
          partitions = lib.mkForce {
            "10-system" = {
              storePaths = [ config.system.build.toplevel ];
              contents = {
                "/etc/os-release".source = config.environment.etc.os-release.source;
                "/sbin/init".source = "${config.system.build.toplevel}/init";
              };
              repartConfig = {
                Format = "xfs";
                GrowFileSystem = false;
                Type = "root";
                Minimize = "guess";
                ReadOnly = false;
                SizeMinBytes = "8G";
                Weight = 100;
              };
            };
            "20-home" = {
              repartConfig = {
                Type = "home";
                Format = "btrfs";
                GrowFileSystem = true;
                SizeMinBytes = "64G";
                Weight = 2000;
              };
            };
            "30-swap" = {
              repartConfig = {
                Type = "swap";
                SizeMinBytes = "8G";
                SizeMaxBytes = "8G";
              };
            };
            "30-var" = {
              repartConfig = {
                Type = "var";
                Format = "btrfs";
                FactoryReset = true;
                GrowFileSystem = false;
                SizeMinBytes = "32G";
                Weight = 1500;
              };
            };
          };
        };
      };
    };
  networking = {
    hostId = "5eeea9df";
    hostName = "hl-dev-x-01";

    firewall = {
      allowedTCPPorts = [
        8000
        8080
        9000
      ];
    };
  };
  nixpkgs = {
    hostPlatform = "x86_64-linux";
  };
  programs = {
    nix-ld = {
      enable = true;
    };
  };
  security = {
    sudo = {
      wheelNeedsPassword = false;
    };
  };
  system = {
    stateVersion = "26.05";
  };
  users = {
    users = {
      developer = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "docker"
        ];
        openssh = {
          authorizedKeys = {
            keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGs63WIkcWBEVHzc9Evjt/57Ikf9WPD1u7oFQVMO7e2a"
            ];
          };
        };
      };
    };
  };
  virtualisation = {
    docker = {
      enable = true;
    };
  };
}
