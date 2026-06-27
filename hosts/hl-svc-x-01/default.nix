{
  inputs,
  ...
}:
let
  hl-svc-x-01 = inputs.self.lib.mkNixOsSystem {
    modules = [
      ./configuration.nix
    ];
  };
in
{
  _file = ./default.nix;

  deploy-rs = {
    nodes = {
      hl-svc-x-01 = {
        hostname = "hl-svc-x-01";
        profilesOrder = [
          "system"
        ];
        profiles = {
          system = {
            user = "root";
            sshUser = "root";
            path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos hl-svc-x-01.config.system.build.images.lxc.passthru;
          };
        };
      };
    };
  };

  flake = {
    nixosConfigurations = {
      inherit hl-svc-x-01;
    };
  };
}
