{
  config,
  lib,
  ...
}:
let
  cfg = config.homelab.nspawn;
  inherit (lib) mkEnableOption mkOption;

  containersWithDeployGroup = lib.filterAttrs (_: value: value.deployGroup != "root") cfg.containers;
in
{
  options = {
    homelab.nspawn = {
      enable = mkEnableOption "nspawn containers" // {
        default = true;
      };
      deployGroup = mkOption {
        type = lib.types.str;
        default = "wheel";
        description = "Default deployGroup for the containers";
      };
      containers = mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              autostart = mkEnableOption "at startup" // {
                default = true;
              };
              deployGroup = mkOption {
                type = lib.types.str;
                default = cfg.deployGroup;
                description = "Group allowed to deploy this container (restart service)";
              };
              enableDocker = mkEnableOption "docker";
              secrets = mkOption {
                description = "Secrets to load into the container as systemd credentials";
                default = { };
                type = lib.types.attrsOf lib.types.str;
              };
              systemdConfig = mkOption {
                type = lib.types.attrs;
                default = { };
                description = "Configuration passed to systemd-nspawn@.service";
              };
              nspawnConfig = mkOption {
                type = lib.types.attrs;
                default = { };
                description = "Configuration of /etc/systemd/nspawn/name.nspawn";
              };
            };
          }
        );
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.mapAttrsToList (name: value: {
      assertion = lib.hasAttr value.deployGroup config.users.groups;
      message = "homelab.nspawn.${name}.deployGroup: group \"${value.deployGroup}\" does not exist in users.groups";
    }) containersWithDeployGroup;

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
      useDHCP = false;
      useNetworkd = true;
    };

    services = {
      resolved = {
        enable = true;
      };
    };

    security = {
      polkit = {
        enable = lib.mkIf (containersWithDeployGroup != { }) true;
        extraConfig = lib.concatStrings (
          lib.mapAttrsToList (name: value: ''
            // Allow the ${value.deployGroup} group to restart the ${name} container
            // (used by the deploy-container script after updating the system profile)
            polkit.addRule(function(action, subject) {
              if (action.id === "org.freedesktop.systemd1.manage-units" &&
                  action.lookup("unit") === "systemd-nspawn@${name}.service" &&
                  subject.isInGroup(${builtins.toJSON value.deployGroup})) {
                return polkit.Result.YES;
              }
            });
            // Allow the ${value.deployGroup} group to open a shell inside the ${name} container
            // (via machinectl shell / machinectl login)
            polkit.addRule(function(action, subject) {
              if ((action.id === "org.freedesktop.machine1.shell" ||
                   action.id === "org.freedesktop.machine1.login" ||
                   action.id === "org.freedesktop.machine1.manage-machines") &&
                  action.lookup("machine") === ${builtins.toJSON name} &&
                  subject.isInGroup(${builtins.toJSON value.deployGroup})) {
                return polkit.Result.YES;
              }
            });
          '') containersWithDeployGroup
        );
      };
    };

    systemd = {
      services = lib.mapAttrs' (
        name: value:
        let
          hasSecrets = value.secrets != { };
          loadCredentials = builtins.map (credential: "--load-credential=${credential}:${credential}") (
            builtins.attrNames value.secrets
          );
        in
        lib.nameValuePair "systemd-nspawn@${name}" (
          lib.mkMerge [
            value.systemdConfig
            {
              overrideStrategy = "asDropin";
              restartTriggers = [
                (lib.toJSON config.systemd.nspawn.${name})
              ];
              serviceConfig = {
                ExecStart = [
                  ""
                  "systemd-nspawn --keep-unit --settings=override --machine=%i ${lib.escapeShellArgs loadCredentials}"
                ];
                LoadCredential = lib.mapAttrsToList (n: v: "${n}:${v}") value.secrets;
              };
              stopIfChanged = false;
              unitConfig = {
                After = lib.mkIf hasSecrets [ "sops-nix.service" ];
                # ConditionPathExists = "/var/lib/machines/${name}";
              };
              wantedBy = lib.optional value.autostart "machines.target";
            }
          ]
        )
      ) cfg.containers;
      nspawn = builtins.listToAttrs (
        lib.lists.imap0 (
          i:
          { name, value }:
          lib.nameValuePair name (
            lib.mkMerge [
              value.nspawnConfig
              {
                execConfig = {
                  Boot = lib.mkDefault true;
                  NoNewPrivileges = lib.mkDefault true;
                  PrivateUsers = lib.mkDefault "pick";
                  LinkJournal = lib.mkDefault "try-guest";
                  Timezone = lib.mkDefault "off";
                };
                filesConfig = {
                  PrivateUsersOwnership = lib.mkDefault "auto";
                };
                networkConfig = {
                  Private = lib.mkDefault true;
                  VirtualEthernet = lib.mkDefault true;
                };
              }
              (lib.mkIf value.enableDocker {
                execConfig = {
                  Capability = "CAP_SETUID CAP_SETGID CAP_SYS_ADMIN";
                  SystemCallFilter = "@keyring bpf";
                  # TODO(PigeonF): See if this can be removed once nsresourced is available
                  PrivateUsers =
                    let
                      n = 65536;
                      per = 3;
                      start = 655356 * 10;
                    in
                    "${toString (start + i * per * n)}:${toString (n * per)}";
                };
                filesConfig = {
                  Bind = [ "/sys/:/run/sys" ];
                };
              })
            ]
          )
        ) (lib.mapAttrsToList lib.nameValuePair cfg.containers)
      );
      tmpfiles = {
        rules = [
          "d /nix/var/nix/profiles/per-container 0755 root root -"
        ];
      };
    };
  };
}
