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
      inputs.self.nixosModules.nspawnImage
      inputs.self.nixosModules.vmspawnImage
      (
        { lib, ... }:
        {
          nixpkgs = {
            hostPlatform = system;
          };
          systemd = {
            enableStrictShellChecks = lib.mkDefault true;
          };
        }
      )
    ]
    ++ modules;
    specialArgs = {
      inherit homelabModulesPath inputs;
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
