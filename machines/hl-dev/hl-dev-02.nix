{ ... }:
{
  imports = [
    ./configuration.nix
    ./users/reviewer.nix
  ];

  config = {
    homelab = {
      systemd-machine = {
        limit = "32G";
      };
    };
    networking = {
      hostId = "a5ead195";
      hostName = "hl-dev-02";
    };
    users = {
      users = {
        reviewer = {
          openssh = {
            authorizedKeys = {
              keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILDI7PcP12iuKicZm22mlb5D0WIbBFuvHGQwNCJqrhaV"
              ];
            };
          };
        };
      };
    };
  };
}
