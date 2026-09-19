{
  config,
  pkgs,
  lib,
  ...
}:
{
  options = {
    homelab = {
      vmspawn =
        let
          instanceOptions = {
            options = {
              autostart = lib.mkEnableOption "run at startup" // {
                default = true;
              };
              enable = lib.mkEnableOption "enable the nspawn container" // {
                default = true;
              };
              ephemeral = lib.mkEnableOption "ephemeral container";
              pass-ssh-keys = lib.mkEnableOption "ephemeral container";
            };
          };
        in
        {
          vms = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule instanceOptions);
          };
        };
    };
  };

  config =
    let
      cfg = config.homelab.vmspawn;
    in
    lib.mkMerge [
      {
        environment = {
          etc = {
            "qemu/firmware".source = "${pkgs.qemu_kvm}/share/qemu/firmware";
          };
          systemPackages = [
            pkgs.systemd-vmspawn-ssh-proxy
            pkgs.qemu_kvm
            pkgs.swtpm
            pkgs.virtiofsd
          ];
        };
        networking = {
          firewall = {
            interfaces =
              let
                allowedUDPPorts = [ 67 ];
                wildcard = if config.networking.nftables.enable then "*" else "+";
              in
              {
                # DHCP on networkd managed interface
                "vt-${wildcard}" = {
                  inherit allowedUDPPorts;
                };
              };
          };
        };
        systemd = {
          additionalUpstreamSystemUnits = [ "systemd-vmspawn@.service" ];
          additionalUpstreamUserUnits = [ "systemd-vmspawn@.service" ];
          services = {
            "systemd-vmspawn@" = {
              path = [
                pkgs.openssh # ssh-keygen
                pkgs.qemu_kvm
                pkgs.virtiofsd
              ];
            };
          };
          tmpfiles = {
            rules = [
              "d /nix/var/nix/profiles/per-deployment 0755 root root -"
            ];
          };
        };
      }
      (lib.mkIf (cfg.vms != { }) {
        systemd = {
          services =
            let
              path = [
                pkgs.openssh # ssh-keygen
                pkgs.qemu_kvm
                pkgs.virtiofsd
              ];
            in
            {
              "systemd-vmspawn@" = {
                inherit path;
              };
            }
            // lib.mapAttrs' (
              name: value:
              lib.nameValuePair "systemd-vmspawn@${name}" (
                lib.mkIf value.enable {
                  overrideStrategy = "asDropin";
                  inherit path;
                  serviceConfig = {
                    ExecStart = [
                      ""
                      (lib.strings.join " " (
                        [
                          "systemd-vmspawn --quiet --register=yes --keep-unit --network-tap --machine=%i"
                          "--pass-ssh-key=${lib.boolToYesNo value.pass-ssh-keys}"
                        ]
                        ++ lib.lists.optional value.ephemeral "--ephemeral"
                      ))
                    ];
                  };
                  stopIfChanged = false;
                  wantedBy = lib.optional value.autostart "machines.target";
                }
              )
            ) cfg.vms;
        };
      })
    ];
}
