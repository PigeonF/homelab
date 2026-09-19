{ ... }:
{
  imports = [
    ./configuration.nix
    ./users/developer.nix
  ];

  config = {
    networking = {
      hostId = "de567892";
      hostName = "hl-dev-01";
    };
    security = {
      sudo = {
        wheelNeedsPassword = false;
      };
    };
    users = {
      users = {
        developer = {
          openssh = {
            authorizedKeys = {
              keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGs63WIkcWBEVHzc9Evjt/57Ikf9WPD1u7oFQVMO7e2a"
              ];
            };
          };
        };
      };
    };
  };
}
