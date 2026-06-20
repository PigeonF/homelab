{
  modulesPath,
  homelabModulesPath,
  lib,
  ...
}:
{
  imports = [
    (homelabModulesPath + "/profiles/base.nix")
    (homelabModulesPath + "/virtualisation/nspawn-image.nix")
    (modulesPath + "/profiles/headless.nix")
    (modulesPath + "/profiles/image-based-appliance.nix")
    (modulesPath + "/profiles/perlless.nix")
  ];
  config = {
    system = {
      disableInstallerTools = true;
      forbiddenDependenciesRegexes = lib.mkForce [ ];
      etc = {
        overlay = {
          # Gives a permission issue when run with restricted permissions
          enable = false;
        };
      };
    };
    time = {
      timeZone = "UTC";
    };
    users = {
      allowNoPasswordLogin = true;
    };
    virtualisation = {
      docker = {
        enable = true;
      };
    };
  };
}
