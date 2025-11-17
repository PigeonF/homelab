_: {
  imports = [ ./hardware-configuration.nix ];

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
      };
      efi = {
        canTouchEfiVariables = true;
      };
    };
  };

  networking = {
    hostName = "hl-vhost-x-01";
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
