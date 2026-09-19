{
  config = {
    image = {
      modules = {
        vmspawn =
          {
            lib,
            config,
            pkgs,
            modulesPath,
            ...
          }:
          {
            options = {
              virtualisation = {
                vmspawnImage = {
                  ssh-vsock = lib.mkEnableOption "enable automatic systemd ssh vsock integration" // {
                    default = true;
                  };
                };
              };
            };

            imports = [ (modulesPath + "/image/file-options.nix") ];

            config =
              let
                cfg = config.virtualisation.vmspawnImage;
              in
              {
                boot = {
                  initrd = {
                    availableKernelModules = [
                      "virtio_net"
                      "virtio_pci"
                      "virtio_mmio"
                      "virtio_blk"
                      "virtio_scsi"
                      "9p"
                      "9pnet_virtio"
                      "virtiofs"
                    ];
                    enable = true;
                    kernelModules = [
                      "virtio_balloon"
                      "virtio_console"
                      "virtio_rng"
                      "virtio_gpu"
                    ];
                    systemd = {
                      enable = true;
                      root = "gpt-auto";
                    };
                  };
                  kernelParams = [
                    "systemd.ssh_auto=${toString cfg.ssh-vsock}"
                  ];
                  loader = {
                    # internal option, not visible on search.nixos.org
                    supportsInitrdSecrets = true;
                  }
                  # We boot the kernel directly, so disable any bootloaders
                  // builtins.listToAttrs (
                    builtins.map
                      (name: {
                        inherit name;
                        value = {
                          enable = false;
                        };
                      })
                      [
                        "external"
                        "generic-extlinux-compatible"
                        "grub"
                        "limine"
                        "refind"
                        "systemd-boot"
                      ]
                  );
                };
                hardware = {
                  enableRedistributableFirmware = false;
                  cpu = {
                    amd = {
                      updateMicrocode = false;
                    };
                    intel = {
                      updateMicrocode = false;
                    };
                  };
                };

                console = {
                  # TODO(nix-release): Remove on 26.11 (https://github.com/NixOS/nixpkgs/pull/480686)
                  enable = lib.mkOverride 99 true;
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

                    "sshd-vsock@" = {
                      serviceConfig = {
                        ExecSearchPath = lib.mkOverride 99 (
                          lib.makeBinPath [
                            config.services.openssh.package
                            config.systemd.package
                          ]
                        );
                      };
                    };
                  };
                };

                system = {
                  build = {
                    image = lib.mkOverride 99 config.system.build.tarball;

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
                          source = config.system.build.toplevel + "/etc/os-release";
                          target = "/etc/os-release";
                        }
                        {
                          source = config.system.build.uki;
                          target = "/boot/uki";
                        }
                        {
                          source = pkgs.writeText "nixos-boot-loader.conf" ''
                            linux /uki/${config.system.boot.loader.ukiFile}
                          '';
                          target = "/boot/loader/entries/nixos.conf";
                        }
                      ];
                      extraCommands = ''
                        mkdir -p dev proc sys usr
                      '';
                    };
                  };

                  nixos = {
                    tags = [ "vmspawn" ];
                  };
                };

                image = {
                  extension = "tar.xz";
                  filePath = "tarball/${config.image.fileName}";
                };

                # Allow the user to login as root without password.
                users.users.root.initialHashedPassword = lib.mkOverride 150 "";
                services.openssh.enable = true;
                services.getty.helpLine = ''

                  Log in as "root" with an empty password.
                '';
              };
          };
      };
    };
  };
}
