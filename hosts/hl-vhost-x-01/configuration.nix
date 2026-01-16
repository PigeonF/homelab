{
  disko,
  impermanence,
  nixos-facter-modules,
  sops-nix,
  self,
  config,
  pkgs,
  ...
}:
let
  homelab = self;
in
{
  imports = [
    ./networking.nix
    homelab.nixosModules.mixins-boot
    homelab.nixosModules.mixins-common
    homelab.nixosModules.mixins-environment
    homelab.nixosModules.mixins-networking
    homelab.nixosModules.mixins-nix
    homelab.nixosModules.mixins-openssh
    homelab.nixosModules.nspawn-containers
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
    nspawn-containers = {
      containers = {
        "hl-dev-x-01" = {
          enableDocker = true;
          enableSudo = true;
        };
        "hl-dev-x-02" = {
          ephemeral = true;
        };
        "hl-ci-x-01" = {
          enableDocker = true;
          secrets = {
            "auth-config-docker" = config.sops.secrets."hl-ci-x-01/gitlab-runner/auth-config-docker".path;
          };
        };
        "hl-ci-x-02" = {
          enableDocker = true;
          secrets = {
            "auth-config-docker" = config.sops.secrets."hl-ci-x-02/gitlab-runner/auth-config-docker".path;
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
    secrets = {
      "hl-ci-x-01/gitlab-runner/auth-config-docker" = {
        sopsFile = ./secrets/hl-ci-x-01.yaml;
        key = "gitlab-runner/auth-config-docker";
        restartUnits = [ "systemd-nspawn@hl-ci-x-01.service" ];
      };
      "hl-ci-x-02/gitlab-runner/auth-config-docker" = {
        sopsFile = ./secrets/hl-ci-x-02.yaml;
        key = "gitlab-runner/auth-config-docker";
        restartUnits = [ "systemd-nspawn@hl-ci-x-02.service" ];
      };
    };
  };

  services = {
    pcscd = {
      enable = true;
    };
  };

  system = {
    stateVersion = "25.11";
  };

  systemd = {
    additionalUpstreamSystemUnits = [ "systemd-vmspawn@.service" ];
    additionalUpstreamUserUnits = [ "systemd-vmspawn@.service" ];
    services = {
      "systemd-nspawn@hl-ci-x-01" = {
        serviceConfig = {
          CPUQuota = "400%";
          MemoryHigh = "8G";
          MemoryMax = "12G";
        };
      };
      "systemd-nspawn@hl-ci-x-02" = {
        serviceConfig = {
          CPUQuota = "400%";
          MemoryHigh = "8G";
          MemoryMax = "12G";
        };
      };
    };
  };

  users = {
    users = {
      administrator = {
        isNormalUser = true;
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
