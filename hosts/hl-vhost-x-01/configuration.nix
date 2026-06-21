{
  homelabModulesPath,
  config,
  pkgs,
  inputs,
  ...
}:
let
  homelab = inputs.self;
  inherit (inputs)
    disko
    impermanence
    nixos-facter-modules
    sops-nix
    ;
in
{
  imports = [
    (homelabModulesPath + "/profiles/base.nix")
    (homelabModulesPath + "/profiles/interactive.nix")
    ./networking.nix
    homelab.nixosModules.nspawn-host
    sops-nix.nixosModules.sops
    {
      imports = [
        disko.nixosModules.disko
        impermanence.nixosModules.impermanence
        ./disko.nix
      ];
    }
    {
      imports = [ nixos-facter-modules.nixosModules.facter ];
      config = {
        facter = {
          detected = {
            bluetooth = {
              enable = false;
            };
            dhcp = {
              enable = false;
            };
          };
          reportPath = ./facter.json;
        };
      };
    }
  ];
  boot = {
    binfmt = {
      emulatedSystems = [
        "aarch64-linux"
        "armv7l-linux"
        "i686-linux"
        "powerpc64le-linux"
        "riscv64-linux"
        "s390x-linux"
      ];
      preferStaticEmulators = true;
    };
    loader = {
      efi = {
        canTouchEfiVariables = true;
      };
    };
  };
  environment = {
    etc = {
      "qemu/firmware".source = "${pkgs.qemu_kvm}/share/qemu/firmware";
    };
    systemPackages = [
      pkgs.qemu_kvm
      pkgs.swtpm
      pkgs.virtiofsd
    ];
  };
  homelab = {
    nspawn = {
      containers = {
        "hl-dev-x-01" = {
          enableDocker = true;
          nspawnConfig = {
            execConfig = {
              # Enable `sudo`
              NoNewPrivileges = false;
            };
            networkConfig = {
              Bridge = "br-public";
            };
          };
        };
        "hl-ci-x-01" = {
          enableDocker = true;
          secrets = {
            "auth-config-docker" = config.sops.secrets."hl-ci-x-01/gitlab-runner/auth-config-docker".path;
          };
          nspawnConfig = {
            execConfig = {
              Ephemeral = true;
            };
          };
          systemdConfig = {
            serviceConfig = {
              CPUQuota = "200%";
              MemoryHigh = "6G";
              MemoryMax = "8G";
            };
          };
        };
        "hl-ci-x-02" = {
          enableDocker = true;
          secrets = {
            "auth-config-cross" = config.sops.secrets."hl-ci-x-02/gitlab-runner/auth-config-cross".path;
            "auth-config-docker" = config.sops.secrets."hl-ci-x-02/gitlab-runner/auth-config-docker".path;
          };
          nspawnConfig = {
            execConfig = {
              Ephemeral = true;
            };
          };
          systemdConfig = {
            serviceConfig = {
              CPUQuota = "400%";
              MemoryHigh = "8G";
              MemoryMax = "12G";
            };
          };
        };
        "hl-ci-x-03" = {
          enableDocker = true;
          secrets = {
            "auth-config-docker" = config.sops.secrets."hl-ci-x-03/gitlab-runner/auth-config-docker".path;
          };
          nspawnConfig = {
            execConfig = {
              Ephemeral = true;
            };
          };
          systemdConfig = {
            serviceConfig = {
              CPUQuota = "200%";
              MemoryHigh = "6G";
              MemoryMax = "8G";
            };
          };
        };
      };
    };
  };
  networking = {
    hostId = "5ee11178";
    hostName = "hl-vhost-x-01";
  };
  security = {
    sudo = {
      wheelNeedsPassword = false;
    };
  };
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      "hl-ci-x-01/gitlab-runner/auth-config-docker" = {
        restartUnits = [ "systemd-nspawn@hl-ci-x-01.service" ];
      };
      "hl-ci-x-02/gitlab-runner/auth-config-docker" = {
        restartUnits = [ "systemd-nspawn@hl-ci-x-02.service" ];
      };
      "hl-ci-x-02/gitlab-runner/auth-config-cross" = {
        restartUnits = [ "systemd-nspawn@hl-ci-x-02.service" ];
      };
      "hl-ci-x-03/gitlab-runner/auth-config-docker" = {
        restartUnits = [ "systemd-nspawn@hl-ci-x-03.service" ];
      };
    };
  };
  services = {
    pcscd = {
      enable = true;
    };
  };
  system = {
    stateVersion = "26.05";
  };
  systemd = {
    additionalUpstreamSystemUnits = [ "systemd-vmspawn@.service" ];
    additionalUpstreamUserUnits = [ "systemd-vmspawn@.service" ];
  };
  users = {
    users = {
      administrator = {
        isNormalUser = true;
        initialHashedPassword = "";
        extraGroups = [
          "wheel"
        ];
        openssh = {
          authorizedKeys = {
            keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAffg99C3TKcCLgrCEhhg89maKzPpdOP6lDi4gRCCIm1"
            ];
          };
        };
      };
    };
  };
}
