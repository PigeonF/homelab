{
  config,
  lib,
  ...
}:
let
  cfg = config.homelab.nspawn-containers;
  inherit (lib) mkEnableOption mkOption;
in
{
  options = {
    homelab.nspawn-containers = {
      enable = mkEnableOption "nspawn configurations" // {
        default = true;
      };
      containers = mkOption {
        description = "Container configurations";
        default = { };

        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              enableDocker = mkEnableOption "docker";
              enableSudo = mkEnableOption "sudo";
              ephemeral = mkOption {
                type = lib.types.bool;
                default = false;
              };
              secrets = mkOption {
                description = "Secrets to load into the container";
                default = { };
                type = lib.types.attrsOf lib.types.str;
              };
            };
          }
        );
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd = {
      nspawn = builtins.listToAttrs (
        lib.lists.imap0 (
          i:
          { name, value }:
          lib.nameValuePair name {
            execConfig = lib.mkMerge [
              {
                Boot = true;
                NoNewPrivileges = lib.mkDefault true;
                PrivateUsers = lib.mkDefault "pick";
                LinkJournal = "try-guest";
                Timezone = "off";
              }
              (lib.mkIf value.ephemeral {
                Ephemeral = true;
              })
              (lib.mkIf value.enableSudo {
                NoNewPrivileges = false;
              })
              (lib.mkIf value.enableDocker {
                Capability = "CAP_SETUID CAP_SETGID CAP_SYS_ADMIN";
                SystemCallFilter = "@keyring bpf";
                PrivateUsers =
                  let
                    n = 65536;
                    per = 3;
                    start = 655356 * 10;
                  in
                  "${toString (start + i * per * n)}:${toString (n * per)}";
              })
            ];
            filesConfig = {
              PrivateUsersOwnership = "auto";
              Bind = lib.mkIf value.enableDocker [ "/sys:/run/sys" ];
            };
            networkConfig = {
              Private = true;
              VirtualEthernet = true;
              Bridge = "br0";
            };
          }
        ) (lib.mapAttrsToList lib.nameValuePair cfg.containers)
      );
      services = lib.mapAttrs' (
        name: container:
        lib.nameValuePair "systemd-nspawn@${name}" (
          lib.mkMerge [
            {
              unitConfig = {
                ConditionPathExists = "/var/lib/machines/${name}";
              };
              overrideStrategy = "asDropin";
            }
            (lib.mkIf (container.secrets != { }) {
              serviceConfig = {
                LoadCredential = lib.mapAttrsToList (n: v: "${n}:${v}") container.secrets;
                ExecStart =
                  let
                    loadCredentials = builtins.map (credential: "--load-credential=${credential}:${credential}") (
                      builtins.attrNames container.secrets
                    );
                  in
                  [
                    ""
                    "systemd-nspawn --keep-unit --settings=override --machine=%i ${lib.escapeShellArgs loadCredentials}"
                  ];
              };
              unitConfig = {
                After = [ "sops-nix.service" ];
              };
            })
            (lib.mkIf (!container.ephemeral) {
              wantedBy = [ "machines.target" ];
            })
          ]
        )
      ) cfg.containers;
    };
  };
}
