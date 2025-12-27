{
  # systemd = {
  #   network = {
  #     networks = {
  #       "10-docker-bridge" = {
  #         matchConfig = {
  #           Type = "bridge";
  #           Name = "docker*";
  #         };
  #         linkConfig = {
  #           Unmanaged = true;
  #         };
  #       };
  #       "10-docker-veth" = {
  #         matchConfig = {
  #           Type = "ether";
  #           Name = "veth*";
  #         };
  #         linkConfig = {
  #           Unmanaged = true;
  #         };
  #       };
  #     };
  #   };
  # };
  virtualisation = {
    docker = {
      enable = true;
    };
  };
}
