{
  homelabModulesPath,
  lib,
  ...
}:
{
  imports = [
    (homelabModulesPath + "/profiles/systemd-machine.nix")
    (homelabModulesPath + "/profiles/systemd-networking.nix")
  ];

  config = {
    networking = {
      hostId = lib.mkDefault "68f0b183";
      hostName = lib.mkDefault "hl-dev";
    };
    system = {
      stateVersion = "26.05";
    };
  };
}
