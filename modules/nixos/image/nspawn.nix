{
  config = {
    image = {
      modules = {
        nspawn =
          {
            lib,
            config,
            pkgs,
            modulesPath,
            ...
          }:
          {
            options = { };

            imports = [ (modulesPath + "/image/file-options.nix") ];

            config = {
              boot = {
                isContainer = true;
                isNspawnContainer = true;
              };

              console = {
                # TODO(nix-release): Remove on 26.11 (https://github.com/NixOS/nixpkgs/pull/480686)
                enable = lib.mkOverride 999 true;
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
                              exec -a nix-daemon ${lib.getExe' config.nix.package "nix-daemon"} --daemon --store local
                            '';
                          };
                        in
                        [
                          ""
                          "${lib.getExe' pkgs.util-linux "unshare"} -m ${lib.getExe start-nix-daemon}"
                        ];
                    };
                  };

                  # https://github.com/NixOS/nixpkgs/blob/release-26.05/nixos/modules/virtualisation/lxc-container.nix
                  register-nix-paths = {
                    description = "Register Nix Store Paths";
                    unitConfig = {
                      DefaultDependencies = false;
                      ConditionPathExists = "/nix-path-registration";
                    };
                    wantedBy = [ "sysinit.target" ];
                    before = [
                      "sysinit.target"
                      "shutdown.target"
                      "nix-daemon.socket"
                      "nix-daemon.service"
                    ];
                    after = [ "local-fs.target" ];
                    conflicts = [ "shutdown.target" ];
                    restartIfChanged = false;
                    serviceConfig = {
                      Type = "oneshot";
                      RemainAfterExit = true;
                    };
                    script = ''
                      ${lib.getExe' config.nix.package "nix-store"} --load-db < /nix-path-registration
                      rm /nix-path-registration

                      # nixos-rebuild also requires a "system" profile
                      ${lib.getExe' config.nix.package "nix-env"} -p /nix/var/nix/profiles/system --set /run/current-system
                    '';
                  };
                };
              };

              system = {
                build = {
                  image = lib.mkOverride 999 config.system.build.tarball;

                  tarball = pkgs.callPackage (modulesPath + "/../lib/make-system-tarball.nix") {
                    fileName = config.image.baseName;
                    extraArgs = "--owner=0";
                    storeContents = [
                      {
                        object = config.system.build.toplevel;
                        symlink = "none";
                      }
                    ];
                    contents = [
                      {
                        source = config.system.build.toplevel + "/init";
                        target = "/sbin/init";
                      }
                      {
                        source = config.system.build.toplevel + "/etc/os-release";
                        target = "/etc/os-release";
                      }
                    ];
                    extraCommands = "mkdir -p dev proc sys usr";
                  };
                };

                nixos = {
                  tags = [ "nspawn" ];
                };
              };

              image = {
                extension = "tar.xz";
                filePath = "tarball/${config.image.fileName}";
              };

              # Allow the user to login as root without password.
              users.users.root.initialHashedPassword = lib.mkOverride 150 "";
              services.getty.helpLine = ''

                Log in as "root" with an empty password.
              '';
            };
          };
      };
    };
  };
}
