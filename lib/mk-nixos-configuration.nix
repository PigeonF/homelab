{ inputs, ... }:

args@{
  system,
  specialArgs ? { },
  homelabModulesPath ? ../modules,
  nixpkgs ? inputs.nixpkgs,
  modules ? [ ],
  ...
}:
nixpkgs.lib.nixosSystem (
  {
    modules = [
      inputs.self.nixosModules.nspawn'
      inputs.self.nixosModules.nspawnImage
      inputs.self.nixosModules.vmspawnImage
      (
        { lib, ... }:
        {
          nixpkgs = {
            hostPlatform = system;
            overlays = builtins.attrValues inputs.self.overlays;
          };
          systemd = {
            enableStrictShellChecks = lib.mkDefault true;
          };
        }
      )
    ]
    ++ modules;
    specialArgs = {
      inherit homelabModulesPath;
      inherit (inputs) self dotfiles home-manager;
    }
    // specialArgs;
  }
  // builtins.removeAttrs args [
    "modules"
    "nixpkgs"
    "specialArgs"
    "system"
  ]
)
