{
  pkgs,
  lib,
  nixpkgs,
  modulesPath,
  home-manager,
  dotfiles,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/minimal.nix")
    ./nspawn-container.nix
    home-manager.nixosModules.home-manager
  ];

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
      XCOMPOSECACHE = "$XDG_CACHE_HOME/X11/xcompose";
    };
  };

  # This configuration is intended for use in an ephemeral container, so we
  # import the home manager configurations directly.
  home-manager = {
    users = {
      reviewer = {
        imports = [ dotfiles.homeModules.reviewer ];
        dotfiles = {
          dotter = {
            extraArgs = [
              "--cache-file"
              "/tmp/dotter-cache.toml"
              "--cache-directory"
              "/tmp/dotter-cache"
            ];
          };
        };
        home = {
          file = {
            "git/github.com/PigeonF/dotfiles" = {
              source = dotfiles;
            };
          };
        };
      };
    };
  };

  i18n = {
    extraLocales = [ "all" ];
  };

  networking = {
    domain = "internal";
    hostName = "hl-dev-x-02";
    nftables = {
      enable = true;
    };
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
      auto-allocate-uids = false;
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

  nixpkgs = {
    hostPlatform = "x86_64-linux";
  };

  security = {
    sudo = {
      extraConfig = ''
        Defaults:root,%wheel env_keep+=TERMINFO_DIRS
        Defaults:root,%wheel env_keep+=SSH_AUTH_SOCK
      '';
      wheelNeedsPassword = true;
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
    stateVersion = "25.05";
  };

  time = {
    timeZone = "Europe/Berlin";
  };

  users = {
    mutableUsers = false;
    users = {
      reviewer = {
        isNormalUser = true;
        initialHashedPassword = "$y$j9T$EZbEP6uUMPv8ByEvL7duB0$QZWlxuBZjG5wAMAlxk9g.tRPdTu0WIMG3W7xMjTzPK1";
        extraGroups = [
          "wheel"
          "docker"
        ];
        openssh = {
          authorizedKeys = {
            keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILDI7PcP12iuKicZm22mlb5D0WIbBFuvHGQwNCJqrhaV"
            ];
          };
        };
      };
      root = {
        openssh = {
          authorizedKeys = {
            keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFUsisg3Uy08p6Hbo1Navie/JyUSz9BDut0wnq79Ursg"
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
