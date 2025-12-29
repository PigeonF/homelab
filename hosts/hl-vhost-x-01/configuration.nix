{
  disko,
  impermanence,
  nixos-facter-modules,
  sops-nix,
  self,
  ...
}:
let
  homelab = self;
in
{
  imports = [
    ./networking.nix
    ./containers/hl-ci-x-01.nix
    ./containers/hl-ci-x-02.nix
    ./containers/hl-dev-x-01.nix
    ./containers/hl-dev-x-02.nix
    homelab.nixosModules.mixins-boot
    homelab.nixosModules.mixins-common
    homelab.nixosModules.mixins-environment
    homelab.nixosModules.mixins-networking
    homelab.nixosModules.mixins-nix
    homelab.nixosModules.mixins-openssh
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
    loader = {
      efi = {
        canTouchEfiVariables = true;
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

  services = {
    pcscd = {
      enable = true;
    };
  };

  system = {
    stateVersion = "25.11";
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
