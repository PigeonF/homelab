let
  flakeModules = {
    deploy-rs = ./deploy-rs.nix;
  };
in
{
  imports = builtins.attrValues flakeModules;

  flake = {
    inherit flakeModules;
  };
}
