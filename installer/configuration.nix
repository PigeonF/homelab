{
  lib,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];

  environment = {
    systemPackages = [
      pkgs.disko
      pkgs.jq
      pkgs.nixos-facter
      pkgs.nixos-install-tools
      pkgs.rsync
    ];
  };

  image = {
    baseName = lib.mkForce "nixos-installer-${pkgs.stdenv.hostPlatform.system}";
  };

  isoImage = {
    squashfsCompression = "zstd";
  };

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
