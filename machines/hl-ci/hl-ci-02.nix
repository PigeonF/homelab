# gitlab runner for fierlings
{
  imports = [
    ./configuration.nix
  ];

  config = {
    homelab = {
      hl-ci = {
        gitlab-runners = {
          cross = {
            enable = true;
          };
          docker = {
            enable = true;
          };
          plain = {
            enable = true;
          };
        };
      };
      systemd-machine = {
        limit = "32G";
      };
    };
    networking = {
      hostId = "7491c6e5";
      hostName = "hl-ci-02";
    };
  };
}
