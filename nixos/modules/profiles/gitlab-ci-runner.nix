{
  modulesPath,
  homelabModulesPath,
  ...
}:
{
  imports = [
    (homelabModulesPath + "/profiles/base.nix")
    (homelabModulesPath + "/virtualisation/nspawn-image.nix")
    (modulesPath + "/profiles/headless.nix")
    (modulesPath + "/profiles/image-based-appliance.nix")
  ];
  config = {
    system = {
      disableInstallerTools = true;
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
