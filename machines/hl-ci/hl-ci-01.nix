# gitlab runner for head-in-the-clouds
{
  imports = [
    ./configuration.nix
  ];

  config = {
    homelab = {
      hl-ci = {
        gitlab-runners = {
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
      hostId = "73657763";
      hostName = "hl-ci-01";
    };
  };
}
