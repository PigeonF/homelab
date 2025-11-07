{ modulesPath, lib, ... }:
{
  imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];

  networking = {
    hostName = "nixos-installer";
  };

  users = {
    users = {
      # NOTE(PigeonF): Since this is just for the ephemeral installer we just hardcode the passwords.
      nixos = {
        initialHashedPassword = lib.mkForce null;
        initialPassword = "nixos";
      };
      root = {
        initialHashedPassword = lib.mkForce null;
        initialPassword = "root";
      };
    };
  };
}
