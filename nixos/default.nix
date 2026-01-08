{
  imports = [ ./pkgs/bootstrap-nspawn ];
  flake = {
    nixosModules = {
      mixins-boot = ./mixins/boot.nix;
      mixins-common = ./mixins/common.nix;
      mixins-docker = ./mixins/docker.nix;
      mixins-environment = ./mixins/environment.nix;
      mixins-networking = ./mixins/networking.nix;
      mixins-nix = ./mixins/nix.nix;
      mixins-openssh = ./mixins/openssh.nix;
      mixins-podman = ./mixins/podman.nix;
      profiles-nspawn = ./profiles/nspawn-container.nix;
    };
  };
}
