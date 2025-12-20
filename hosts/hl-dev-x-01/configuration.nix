{
  pkgs,
  lib,
  nixpkgs,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/minimal.nix")
    ./nspawn-container.nix
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

  i18n = {
    extraLocales = [ "all" ];
  };

  networking = {
    domain = "internal";
    hostName = "hl-dev-x-01";
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
      auto-allocate-uids = true;
      # download-buffer-size = 512 * 1024 * 1024;
      extra-experimental-features = [
        "flakes"
        "nix-command"
        "no-url-literals"
        "auto-allocate-uids"
        "cgroups"
      ];
      # TODO(PigeonF): Figure out how to make this work within nspawn container
      sandbox = false;
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
      wheelNeedsPassword = false;
    };
  };

  services = {
    # TODO(PigeonF): ssh not enable because of bad networkctl configuration?
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
      developer = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
        ];
        openssh = {
          authorizedKeys = {
            keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICSGbm3QEVQFhYqJM29rQ6WibpQr613KgxoYTr/QvztV"
            ];
          };
        };
      };
    };
  };
}
