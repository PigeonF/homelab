{ inputs, ... }:
let
  inherit (inputs.self.lib)
    mkApp
    ;
in
{
  _file = ./default.nix;

  flake = {
    overlays = {
      systemd-vmspawn-ssh-proxy = final: _: {
        systemd-vmspawn-ssh-proxy = final.callPackage ./package.nix { };
      };
    };
  };

  perSystem =
    {
      self',
      pkgs,
      ...
    }:
    {
      apps = {
        systemd-vmspawn-ssh-proxy = mkApp {
          package = self'.packages.systemd-vmspawn-ssh-proxy;
          description = "Wrap systemd-ssh-proxy and resolve VM's CID using machinectl";
        };
      };
      packages = {
        inherit (pkgs) systemd-vmspawn-ssh-proxy;
      };
    };
}
