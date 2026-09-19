{
  homelabModulesPath,
  home-manager,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    home-manager.nixosModules.home-manager
    (homelabModulesPath + "/profiles/docker.nix")
    (homelabModulesPath + "/profiles/hardening.nix")
    (homelabModulesPath + "/profiles/nix.nix")
    (homelabModulesPath + "/profiles/systemd-machine.nix")
    (homelabModulesPath + "/profiles/systemd-networking.nix")
    (homelabModulesPath + "/profiles/workstation.nix")
  ];

  config = {
    documentation = {
      man = {
        man-db = {
          enable = false;
        };
        mandoc = {
          enable = true;
        };
      };
    };
    environment = {
      enableDebugInfo = true;
      systemPackages = [
        pkgs.man-pages
        pkgs.man-pages-posix
      ];
    };
    networking = {
      firewall = {
        allowedTCPPorts = [
          8000
          8080
          9000
        ];
      };
    };
    programs = {
      nix-ld = {
        enable = true;
      };
    };
    services = {
      nixseparatedebuginfod2 = {
        enable = true;
      };
    };
    system = {
      stateVersion = "26.05";
    };
    systemd = {
      tmpfiles = {
        rules = [
          "L+ /bin/bash - - - - ${lib.getExe pkgs.bash}"
        ];
      };
    };
  };
}
