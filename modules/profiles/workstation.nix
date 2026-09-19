{
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
        enable = lib.mkDefault true;
      };
      info = {
        enable = lib.mkDefault false;
      };
      nixos = {
        enable = lib.mkOverride 99 true;
      };
    };
    environment = {
      defaultPackages = lib.mkDefault [ ];
      ldso32 = lib.mkDefault null;
      # WARNING(PigeonF): This might break some packages that set environment.profiles if they are not listed here
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
    networking = {
      nftables = {
        enable = lib.mkDefault true;
      };
    };
    security = {
      sudo = {
        extraConfig = lib.mkDefault ''
          Defaults lecture = never
        '';
      };
    };
    services = {
      openssh = {
        enable = lib.mkDefault true;
      };
    };
    time = {
      timeZone = lib.mkDefault "Europe/Berlin";
    };
  };
}
