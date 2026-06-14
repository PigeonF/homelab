{
  lib,
  modulesPath,
  ...
}:
{
  imports = [ ./nspawn-config.nix ];
  config = {
    image = {
      modules = {
        nspawn =
          {
            config,
            ...
          }:
          {
            imports = [
              (modulesPath + "/image/repart.nix")
              (modulesPath + "/virtualisation/disk-size-option.nix")
            ];
            config = {
              assertions = [
                {
                  assertion = !config.system.etc.overlay.enable;
                  message = "etc overlay breaks /etc/machine-id integration";
                }
              ];
              image = {
                repart = {
                  name = config.system.image.id;
                  seed = "random";
                  sectorSize = 4096;
                  imageSize =
                    if config.virtualisation.diskSize == "auto" then
                      "auto"
                    else
                      "${toString config.virtualisation.diskSize}M";
                  partitions = {
                    "10-system" = {
                      storePaths = [ config.system.build.toplevel ];
                      contents = {
                        "/etc/os-release".source = config.environment.etc.os-release.source;
                        "/sbin/init".source = "${config.system.build.toplevel}/init";
                      };
                      repartConfig = {
                        Format = "xfs";
                        GrowFileSystem = false;
                        Type = "root";
                        Minimize = "guess";
                        Weight = 100;
                      };
                    };
                    "30-var" = {
                      repartConfig = {
                        Type = "var";
                        Format = "xfs";
                        FactoryReset = true;
                        GrowFileSystem = true;
                      };
                    };
                  };
                };
              };
              system = {
                etc = {
                  overlay = {
                    # TODO(PigeonF): Figure out if there is a way to use this with nspawn
                    enable = false;
                  };
                };
                image = {
                  id = lib.mkDefault config.networking.hostName;
                };
                nixos = {
                  tags = [ "nspawn" ];
                };
              };
            };
          };
      };
    };
  };
}
