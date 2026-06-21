{
  config,
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
              boot = {
                loader = {
                  initScript = {
                    enable = true;
                  };
                };
              };
              image = {
                repart = {
                  name = config.system.image.id;
                  seed =
                    # NOTE(PigeonF): We don't need an actually secure random seed, so we just re-use the hostId.
                    # We need a different seed for each image, else systemd-nspawn is not able to run two images at once.
                    lib.strings.fixedWidthString 32 "0" (builtins.substring 0 32 config.networking.hostId);
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
            };
          };
      };
    };
    system = {
      image = {
        id = lib.mkDefault config.networking.hostName;
      };
      nixos = {
        tags = [ "nspawn" ];
      };
    };
  };
}
