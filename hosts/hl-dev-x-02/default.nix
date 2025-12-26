{
  lib,
  inputs,
  ...
}:
let
  hl-dev-x-02 = lib.nixosSystem {
    specialArgs = inputs;
    modules = [
      ./configuration.nix
    ];
  };
in
{
  _file = ./default.nix;

  flake = {
    nixosConfigurations = {
      inherit hl-dev-x-02;
    };
  };

  perSystem =
    { pkgs, ... }:
    {
      apps = {
        bootstrap-hl-dev-x-02 = {
          type = "app";
          meta = {
            description = "Bootstrap the hl-dev-x-02 container";
          };
          program = pkgs.writeShellApplication {
            name = "bootstrap-hl-dev-x-02";
            text = ''
              if [ "$EUID" -ne 0 ]; then
                echo 1>&2 "importctl only works with root rights. Rerun with sudo."
                exit 1
              fi

              # Container is ephemeral, so we always want to update the configuration
              if [ -d /var/lib/machines/hl-dev-x-02 ]; then
                echo 1>&2 "hl-dev-x-02 machine exists already. Stopping and removing machine..."
                machinectl stop hl-dev-x-02 || true
                machinectl remove hl-dev-x-02
              fi


              config="''${1:-${inputs.self}#nixosConfigurations.hl-dev-x-02}"
              tarball=$(nix build -L --print-out-paths "$config.config.system.build.tarball")
              importctl -m import-tar "$tarball/tarball/nixos-system-x86_64-linux.tar.xz" hl-dev-x-02
            '';
          };
        };
      };
      packages = {
        hl-dev-x-02 = hl-dev-x-02.config.system.build.toplevel;
      };
    };
}
