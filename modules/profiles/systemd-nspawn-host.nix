{
  config,
  lib,
  ...
}:
{
  options = {
    homelab = {
      nspawn =
        let
          instanceOptions = {
            options = {
              autostart = lib.mkEnableOption "run at startup" // {
                default = true;
              };
              docker = lib.mkEnableOption "docker";
              enable = lib.mkEnableOption "enable the nspawn container" // {
                default = true;
              };
              ephemeral = lib.mkEnableOption "ephemeral container";
              credentials = lib.mkOption {
                description = "Secrets to load into the container as systemd credentials";
                default = { };
                type = lib.types.attrsOf lib.types.str;
              };
            };
          };
        in
        {
          deployGroup = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = "wheel";
            description = "Group allowed to deploy nspawn containers (restart service)";
          };
          containers = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule instanceOptions);
          };
        };
    };
  };

  config =
    let
      cfg = config.homelab.nspawn;
    in
    lib.mkMerge [
      {
        networking = {
          firewall = {
            interfaces =
              let
                allowedUDPPorts = [ 67 ];
                wildcard = if config.networking.nftables.enable then "*" else "+";
              in
              {
                # DHCP on networkd managed interface
                "ve-${wildcard}" = {
                  inherit allowedUDPPorts;
                };
                "vz-${wildcard}" = {
                  inherit allowedUDPPorts;
                };
              };
          };
        };
        systemd = {
          tmpfiles = {
            rules = [
              "d /nix/var/nix/profiles/per-deployment 0755 root root -"
            ];
          };
        };
      }
      (lib.mkIf (cfg.deployGroup != null) {
        assertions = [
          {
            assertion = lib.hasAttr cfg.deployGroup config.users.groups;
            message = "homelab.nspawn.deployGroup: group \"${cfg.deployGroup}\" does not exist in users.groups";
          }
        ];
        security = {
          polkit = {
            enable = lib.mkIf (cfg.deployGroup != null) true;
            extraConfig = ''
              // Allow the ${cfg.deployGroup} group to restart nspawn containers
              polkit.addRule(function(action, subject) {
                if (action.id === "org.freedesktop.systemd1.manage-units" &&
                    subject.isInGroup(${builtins.toJSON cfg.deployGroup})) {
                  return polkit.Result.YES;
                }
              });
              // Allow the ${cfg.deployGroup} group to open a shell inside nspawn containers
              // (via machinectl shell / machinectl login)
              polkit.addRule(function(action, subject) {
                if ((action.id === "org.freedesktop.machine1.shell" ||
                     action.id === "org.freedesktop.machine1.login" ||
                     action.id === "org.freedesktop.machine1.manage-machines") &&
                    subject.isInGroup(${builtins.toJSON cfg.deployGroup})) {
                  return polkit.Result.YES;
                }
              });
            '';
          };
        };
      })
      (lib.mkIf (cfg.containers != { }) {
        systemd = {
          services = lib.mapAttrs' (
            name: value:
            let
              loadCredentials = builtins.map (credential: "--load-credential=${credential}:${credential}") (
                builtins.attrNames value.credentials
              );
            in
            lib.nameValuePair "systemd-nspawn@${name}" (
              lib.mkIf value.enable {
                overrideStrategy = "asDropin";
                restartTriggers = [
                  (lib.toJSON config.systemd.nspawn'.${name})
                ];
                serviceConfig = {
                  ExecStart = [
                    ""
                    "systemd-nspawn --keep-unit --settings=override --machine=%i ${lib.escapeShellArgs loadCredentials}"
                  ];
                  LoadCredential = lib.mapAttrsToList (n: v: "${n}:${v}") value.credentials;
                };
                stopIfChanged = false;
                wantedBy = lib.optional value.autostart "machines.target";
              }
            )
          ) cfg.containers;
          nspawn' = builtins.listToAttrs (
            lib.lists.imap0 (
              i:
              { name, value }:
              lib.nameValuePair name (
                lib.mkIf value.enable {
                  settings = {
                    Exec = {
                      Boot = lib.mkDefault true;
                      Capability = lib.mkIf value.docker (lib.mkDefault "CAP_SETUID CAP_SETGID CAP_SYS_ADMIN");
                      Ephemeral = lib.mkIf value.ephemeral (lib.mkDefault true);
                      LinkJournal = lib.mkDefault "try-guest";
                      NoNewPrivileges = lib.mkDefault true;
                      # TODO(PigeonF): See if this can be removed once nsresourced is available
                      PrivateUsers = lib.mkDefault (
                        if value.docker then
                          let
                            n = 65536;
                            per = 3;
                            start = 655356 * 10;
                          in
                          "${toString (start + i * per * n)}:${toString (n * per)}"
                        else
                          "pick"
                      );
                      SystemCallFilter = lib.mkIf value.docker (lib.mkDefault "@keyring bpf");
                      Timezone = lib.mkDefault "off";
                    };
                    Files = {
                      Bind = lib.mkIf value.docker [ "/sys/:/run/sys" ];
                      PrivateUsersOwnership = lib.mkDefault "auto";
                    };
                    Network = {
                      Private = lib.mkDefault true;
                      VirtualEthernet = lib.mkDefault true;
                    };
                  };
                }
              )
            ) (lib.mapAttrsToList lib.nameValuePair cfg.containers)
          );
        };
      })
    ];
}
