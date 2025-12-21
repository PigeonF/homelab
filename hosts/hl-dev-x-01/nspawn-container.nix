{
  config,
  lib,
  pkgs,
  ...
}:
let
  makeTarball = pkgs.callPackage (pkgs.path + "/nixos/lib/make-system-tarball.nix");
in
{
  boot = {
    isNspawnContainer = true;
    postBootCommands = ''
      # After booting, register the contents of the Nix store in the Nix
      # database.
      if [ -f /nix-path-registration ]; then
        ${config.nix.package.out}/bin/nix-store --load-db < /nix-path-registration &&
        rm /nix-path-registration
      fi
    '';
    specialFileSystems = {
      "/dev".enable = false;
      "/proc".enable = false;
      "/dev/pts".enable = false;
      "/dev/shm".enable = false;
      "/run".enable = false;
    };
  };
  console = {
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
    activationScripts = {
      installInitScript = lib.mkForce ''
        ln -fs $systemConfig/init /sbin/init
      '';
    };
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
          mkdir -p proc sys dev sbin
          ln -sf /nix/var/nix/profiles/system/init sbin/init
        '';
      };
      installBootLoader = pkgs.writeScript "install-sbin-init.sh" ''
        #!${pkgs.runtimeShell}
        ln -fs "$1/init" /sbin/init
      '';
    };
  };
  systemd = {
    network = {
      enable = true;
    };
  };
}
