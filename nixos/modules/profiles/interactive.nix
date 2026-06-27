{
  inputs,
  config,
  lib,
  ...
}:
{
  config = {
    documentation = {
      dev = {
        enable = lib.mkDefault true;
      };
      doc = {
        enable = lib.mkDefault false;
      };
      info = {
        enable = lib.mkDefault false;
      };
      nixos = {
        enable = lib.mkDefault false;
      };
    };
    environment = {
      defaultPackages = lib.mkDefault [ ];
      ldso32 = lib.mkDefault null;
      # WARNING(PigeonF): This might break some packages that set
      # environment.profiles if they are not listed here
      profiles = lib.mkForce (
        lib.optionals config.services.guix.enable [
          "\${XDG_CONFIG_HOME}/guix/current"
          "\${GUIX_HOME_PROFILE:-$HOME/.guix-home/profile}"
          "\${GUIX_PROFILE:-$HOME/.guix-profile}"
        ]
        # nixos/modules/config/users-groups.nix
        ++ [
          # Remove $HOME/.nix-profile
          "\${XDG_STATE_HOME:-$HOME/.local/state}/nix/profile"
          "/etc/profiles/per-user/$USER"
        ]
        ++ lib.optional config.services.linyaps.enable "/var/lib/linglong/entries"
        ++ lib.optionals config.services.flatpak.enable [
          "\${XDG_DATA_HOME:-$HOME/.local/share}/flatpak/exports"
          "/var/lib/flatpak/exports"
        ]
        # nixos/modules/programs/environment.nix
        ++ [
          "/nix/var/nix/profiles/default"
          "/run/current-system/sw"
        ]
      );
      sessionVariables = {
        XDG_BIN_HOME = "$HOME/.local/bin";
        XDG_CACHE_HOME = "$HOME/.cache";
        XDG_CONFIG_HOME = "$HOME/.config";
        XDG_DATA_HOME = "$HOME/.local/share";
        XDG_STATE_HOME = "$HOME/.local/state";
      };
      stub-ld = {
        enable = lib.mkDefault false;
      };
    };
    i18n = {
      extraLocaleSettings = {
        LC_COLLATE = lib.mkDefault "C.UTF-8";
        LC_MEASUREMENT = lib.mkDefault "de_DE.UTF-8";
        LC_MONETARY = lib.mkDefault "de_DE.UTF-8";
        LC_PAPER = lib.mkDefault "de_DE.UTF-8";
        LC_TIME = lib.mkDefault "en_DK.UTF-8"; # Uses yyyy-mm-dd
      };
    };
    nix = {
      channel = {
        enable = lib.mkDefault false;
      };
      daemonCPUSchedPolicy = lib.mkDefault "batch";
      daemonIOSchedClass = lib.mkDefault "idle";
      daemonIOSchedPriority = lib.mkDefault 7;
      optimise = {
        automatic = lib.mkDefault (!config.boot.isContainer);
      };
      registry = {
        nixpkgs = {
          flake = lib.mkDefault inputs.nixpkgs;
        };
        nixpkgs-unstable = {
          flake = lib.mkDefault inputs.nixpkgs-unstable;
        };
        self = {
          flake = inputs.self;
        };
        dotfiles = {
          flake = inputs.dotfiles;
        };
      };
      settings = {
        # nspawn containers do not have enough UIDs assigned for this to work.
        # https://git.lix.systems/lix-project/lix/issues/387#issuecomment-16134
        auto-allocate-uids = lib.mkDefault (!config.boot.isNspawnContainer);
        # download-buffer-size = 512 * 1024 * 1024;
        extra-experimental-features = [
          "auto-allocate-uids"
          "cgroups"
        ];
        sandbox = lib.mkDefault true;
        store = lib.mkDefault "daemon";
        system-features = [ "uid-range" ];
        trusted-users = [ "@wheel" ];
        use-cgroups = lib.mkDefault (!config.boot.isNspawnContainer);
        use-xdg-base-directories = lib.mkDefault true;
      };
    };
    security = {
      sudo = {
        execWheelOnly = lib.mkDefault true;
        extraConfig = ''
          Defaults lecture = never
        '';
      };
    };
    services = {
      openssh = {
        enable = lib.mkDefault true;
      };
    };
    system = {
      tools = {
        nixos-enter = {
          enable = lib.mkDefault false;
        };
        nixos-generate-config = {
          enable = lib.mkDefault false;
        };
        nixos-install = {
          enable = lib.mkDefault false;
        };
        nixos-option = {
          enable = lib.mkDefault false;
        };
      };
    };
    time = {
      timeZone = lib.mkDefault "Europe/Berlin";
    };
  };
}
