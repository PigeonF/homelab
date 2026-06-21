{
  config,
  pkgs,
  lib,
  ...
}:
{
  config = {
    boot = {
      isNspawnContainer = true;
      loader = {
        grub = {
          enable = false;
        };
        systemd-boot = {
          enable = false;
        };
      };
      specialFileSystems = {
        "/dev".enable = false;
        "/dev/pts".enable = false;
        "/dev/shm".enable = false;
        "/proc".enable = false;
        "/run".enable = false;
        "/run/keys".enable = false;
        "/sys".enable = false;
      };
    };
    console = {
      # TODO(arianvp): Remove after https://github.com/NixOS/nixpkgs/pull/480686 is merged
      enable = true;
    };
    systemd = {
      services = {
        # https://github.com/NixOS/nixpkgs/issues/405256
        nix-daemon = {
          serviceConfig = {
            ExecStart =
              let
                start-nix-daemon = pkgs.writeShellApplication {
                  name = "start-nix-daemon";
                  text = ''
                    ${lib.getExe' pkgs.util-linux "mount"} proc -t proc /proc
                    exec -a nix-daemon ${lib.getExe' config.nix.package "nix-daemon"} --daemon
                  '';
                };
              in
              [
                ""
                "${lib.getExe' pkgs.util-linux "unshare"} -m ${lib.getExe start-nix-daemon}"
              ];
          };
        };
      };
    };
  };
}
