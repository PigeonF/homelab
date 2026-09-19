{
  homelabModulesPath,
  sops-nix,
  ...
}:
{
  imports = [
    sops-nix.nixosModules.sops
    (homelabModulesPath + "/profiles/hardening.nix")
    (homelabModulesPath + "/profiles/nix.nix")
    (homelabModulesPath + "/profiles/systemd-networking.nix")
    (homelabModulesPath + "/profiles/systemd-nspawn-host.nix")
    (homelabModulesPath + "/profiles/systemd-vmspawn-host.nix")
    (homelabModulesPath + "/profiles/workstation.nix")
    ./boot.nix
    ./disko.nix
    ./facter.nix
    ./machines/hl-ci-01.nix
    ./machines/hl-ci-02.nix
    ./machines/hl-dev-01.nix
    ./machines/hl-dev-02.nix
    ./machines/hl-svc-01.nix
    ./impermanence.nix
    ./network.nix
    ./users/administrator.nix
    ./users/root.nix
  ];

  config = {
    boot = {
      binfmt = {
        emulatedSystems = [
          "aarch64-linux"
          "armv6l-linux"
          "armv7l-linux"
          "i686-linux"
          "powerpc64le-linux"
          "riscv64-linux"
          "s390x-linux"
        ];
        preferStaticEmulators = true;
      };
    };
    networking = {
      hostId = "30c27c89";
      hostName = "hl-vhost-01";
    };
    security = {
      sudo = {
        wheelNeedsPassword = false;
      };
    };
    services = {
      pcscd = {
        enable = true;
      };
      userborn = {
        enable = true;
      };
    };
    sops = {
      defaultSopsFile = ../../secrets/hl-vhost-01.yaml;
    };
    system = {
      stateVersion = "26.05";
    };
  };
}
