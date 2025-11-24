{
  pkgs,
  lib,
  nixpkgs,
  disko,
  impermanence,
  nixos-facter-modules,
  ...
}:
{
  imports = [
    disko.nixosModules.disko
    ./disko.nix
    impermanence.nixosModules.impermanence
    nixos-facter-modules.nixosModules.facter
    { config.facter.reportPath = ./facter.json; }
  ];

  boot = {
    binfmt = {
      emulatedSystems = [
        "aarch64-linux"
        "wasm32-wasi"
        "wasm64-wasi"
      ];
    };
    initrd = {
      systemd = {
        enable = true;
      };
    };
    loader = {
      efi = {
        canTouchEfiVariables = true;
      };
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
        editor = false;
      };
    };
    tmp = {
      cleanOnBoot = true;
    };
  };

  environment = {
    profiles = lib.mkForce [
      "\${XDG_STATE_HOME:-$HOME/.local/state}/nix/profile"
      "/etc/profiles/per-user/$USER"
      "/nix/var/nix/profiles/default"
      "/run/current-system/sw"
    ];
    sessionVariables = {
      XDG_BIN_HOME = "$HOME/.local/bin";
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_STATE_HOME = "$HOME/.local/state";
    };
    variables = {
      HISTFILE = "$XDG_STATE_HOME/bash/history";
      LESSHISTFILE = "$XDG_STATE_HOME/less/history";
    };
  };

  facter = {
    detected = {
      bluetooth = {
        enable = false;
      };
      dhcp = {
        enable = false;
      };
    };
  };

  i18n = {
    extraLocales = [ "all" ];
  };

  networking = {
    domain = "internal";
    firewall = {
      trustedInterfaces = [ "incusbr0" ];
    };
    hostId = "5ee11178";
    hostName = "hl-vhost-x-01";
    nftables = {
      enable = true;
    };
    useDHCP = false;
    useNetworkd = true;
  };

  nix = {
    channel = {
      enable = false;
    };
    package = pkgs.nixVersions.stable;
    registry = {
      nixpkgs = {
        flake = nixpkgs;
      };
    };
    settings = {
      auto-allocate-uids = true;
      # download-buffer-size = 512 * 1024 * 1024;
      extra-experimental-features = [
        "flakes"
        "nix-command"
        "no-url-literals"
        "auto-allocate-uids"
        "cgroups"
      ];
      sandbox = true;
      system-features = [ "uid-range" ];
      trusted-users = [ "@wheel" ];
      use-cgroups = true;
      use-xdg-base-directories = true;
    };
  };

  security = {
    sudo = {
      extraConfig = ''
        Defaults:root,%wheel env_keep+=TERMINFO_DIRS
        Defaults:root,%wheel env_keep+=SSH_AUTH_SOCK
      '';
      wheelNeedsPassword = false;
    };
  };

  services = {
    openssh = {
      enable = true;
      extraConfig = ''
        AcceptEnv LANG LANGUAGE LC_*
        AcceptEnv COLORTERM TERM TERM_*
      '';
      settings = {
        Macs = [
          "hmac-sha2-512"
          "hmac-sha2-512-etm@openssh.com"
          "hmac-sha2-256-etm@openssh.com"
          "umac-128-etm@openssh.com"
        ];
      };
    };
    resolved = {
      enable = true;
      llmnr = "false";
      extraConfig = ''
        MulticastDNS=yes
      '';
    };
    timesyncd = {
      enable = true;
    };
    userborn = {
      enable = false; # https://github.com/nikstur/userborn/issues/7
    };
  };

  system = {
    stateVersion = "25.11";
  };

  systemd = {
    network = {
      enable = true;
      netdevs = {
        "30-br0" = {
          netdevConfig = {
            Kind = "bridge";
            Name = "br0";
          };
        };
      };
      networks = {
        "40-enp170s0" = {
          matchConfig = {
            Name = "enp170s0";
          };
          networkConfig = {
            Bridge = "br0";
          };
          linkConfig = {
            RequiredForOnline = "enslaved";
          };
        };
        "40-enp171s0" = {
          matchConfig = {
            Name = "enp171s0";
          };
          networkConfig = {
            MulticastDNS = "yes";
            DHCP = "yes";
            UseDomains = "yes";
            IPv6PrivacyExtensions = "kernel";
          };
          linkConfig = {
            RequiredForOnline = "no";
          };
        };
        "40-wlp172s0" = {
          matchConfig = {
            Name = "wlp172s0";
          };
          linkConfig = {
            Unmanaged = "yes";
          };
        };
        "50-br0" = {
          matchConfig = {
            Name = "br0";
          };
          networkConfig = {
            MulticastDNS = "yes";
            # DHCP = "yes";
            UseDomains = "yes";
            IPv6PrivacyExtensions = "kernel";
          };
        };
      };
    };
  };

  time = {
    timeZone = "Europe/Berlin";
  };

  users = {
    mutableUsers = false;
    users = {
      administrator = {
        isNormalUser = true;
        extraGroups = [
          "incus-admin"
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

  virtualisation = {
    incus = {
      enable = true;
      preseed = {
        networks = [
          {
            name = "incusbr0";
            description = "Incus-Internal bridge";
            type = "bridge";
            config = {
              "ipv4.address" = "auto";
              "ipv4.nat" = "true";
              "ipv6.address" = "auto";
              "ipv6.nat" = "true";
            };
          }
        ];
        profiles = [
          {
            name = "default";
            description = "Default incus profile";
            devices = {
              eth0 = {
                name = "eth0";
                network = "incusbr0";
                type = "nic";
              };
              root = {
                path = "/";
                pool = "default";
                type = "disk";
              };
            };
          }
          {
            name = "bridged";
            description = "Instance connected to LAN bridge";
            devices = {
              eth0 = {
                name = "eth0";
                nictype = "bridged";
                parent = "br0";
                type = "nic";
              };
              root = {
                path = "/";
                pool = "default";
                type = "disk";
              };
            };
          }
        ];
        storage_pools = [
          {
            name = "default";
            driver = "zfs";
            config = {
              source = "zroot/local/incus";
            };
          }
        ];
      };
    };
  };
}
