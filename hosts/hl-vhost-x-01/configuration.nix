_: {
  imports = [
    ./disko.nix
    { config.facter.reportPath = ./facter.json; }
  ];

  boot = {
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
      };
    };
  };

  networking = {
    domain = "internal";
    hostId = "5ee11178";
    hostName = "hl-vhost-x-01";
    useNetworkd = true;
  };

  system = {
    stateVersion = "25.11";
  };

  systemd = {
    network = {
      enable = true;
    };
  };

  services = {
    openssh = {
      enable = true;
    };
  };

  users = {
    users = {
      root = {
        initialHashedPassword = "";
        openssh = {
          authorizedKeys = {
            keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGR0JA4clKj7Uz5BBAN6kGFG51jIHXKwRVa8lk/OeJF4"
            ];
          };
        };
      };
    };
  };
}
