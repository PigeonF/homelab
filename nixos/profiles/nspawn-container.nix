{
  config,
  pkgs,
  lib,
  ...
}:
let
  makeTarball = pkgs.callPackage (pkgs.path + "/nixos/lib/make-system-tarball.nix");
in
{
  boot = {
    isNspawnContainer = true;
    postBootCommands = ''
      # After booting, register the contents of the Nix store in the Nix database.
      if [ -f /nix-path-registration ]; then
        ${config.nix.package.out}/bin/nix-store --load-db < /nix-path-registration &&
        ${pkgs.coreutils}/bin/rm /nix-path-registration
      fi

      # nixos-rebuild also requires a "system" profile
      ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system
    '';
    loader = {
      initScript = {
        enable = true;
      };
    };
    specialFileSystems = {
      "/dev".enable = false;
      "/proc".enable = false;
      "/dev/pts".enable = false;
      "/dev/shm".enable = false;
      "/run".enable = false;
    };
  };
  console = {
    # https://github.com/NixOS/nixpkgs/pull/480686
    enable = true;
  };
  networking = {
    useHostResolvConf = false;
    useNetworkd = true;
    useDHCP = false;
  };
  services = {
    openssh = {
      startWhenNeeded = false;
    };
  };
  system = {
    build = {
      tarball = makeTarball {
        extraArgs = "--owner=0";
        storeContents = [
          {
            object = config.system.build.toplevel;
            symlink = "/nix/var/nix/profiles/system";
          }
        ];
        contents = [
          {
            # systemd-nspawn requires this file to exist
            source = config.system.build.toplevel + "/etc/os-release";
            target = "/etc/os-release";
          }
        ];
        extraCommands = pkgs.writeScript "extra-commands" ''
          ${pkgs.coreutils}/bin/mkdir -p proc sys dev sbin
          ${pkgs.coreutils}/bin/ln -sf /nix/var/nix/profiles/system/init sbin/init
        '';
      };
    };
  };
  systemd = {
    network = {
      enable = true;
    };
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
}
