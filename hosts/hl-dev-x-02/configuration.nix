{
  home-manager,
  dotfiles,
  self,
  ...
}:
let
  homelab = self;
in
{
  imports = [
    home-manager.nixosModules.home-manager
    homelab.nixosModules.mixins-common
    homelab.nixosModules.mixins-docker
    homelab.nixosModules.mixins-environment
    homelab.nixosModules.mixins-networking
    homelab.nixosModules.mixins-nix
    homelab.nixosModules.mixins-openssh
    homelab.nixosModules.profiles-nspawn
  ];

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

  networking = {
    hostId = "b4ef2887";
    hostName = "hl-dev-x-02";
  };

  nixpkgs = {
    hostPlatform = "x86_64-linux";
  };

  security = {
    sudo = {
      wheelNeedsPassword = true;
    };
  };

  system = {
    stateVersion = "25.11";
    disableInstallerTools = true;
  };

  users = {
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
}
