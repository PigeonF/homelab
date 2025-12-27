# Configure the system environment
{ config, lib, ... }:
{
  config = {
    environment = {
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
    };
    i18n = {
      extraLocaleSettings = {
        LC_COLLATE = "C.UTF-8";
        LC_MEASUREMENT = "de_DE.UTF-8";
        LC_MONETARY = "de_DE.UTF-8";
        LC_PAPER = "de_DE.UTF-8";
        LC_TIME = "en_DK.UTF-8"; # Uses yyyy-mm-dd
      };
    };
    time = {
      timeZone = "Europe/Berlin";
    };
  };
}
