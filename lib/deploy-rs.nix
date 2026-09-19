{ inputs, ... }:
system:
let
  inherit (inputs.nixpkgs) lib;
  inherit (inputs.deploy-rs.lib."${system}") activate;
  inherit (inputs.self.packages."${system}") deploy-nspawn deploy-vmspawn;
in
{
  activate = activate // {
    nspawn =
      {
        base,
        name,
        limit ? "none",
      }:
      activate.custom base ''
        ${lib.getExe deploy-nspawn} "$PROFILE/${base.passthru.filePath}" "${name}" "${limit}"
      '';
    vmspawn =
      {
        base,
        name,
        limit ? "none",
      }:
      activate.custom base ''
        ${lib.getExe deploy-vmspawn} "$PROFILE/${base.passthru.filePath}" "${name}" "${limit}"
      '';
  };
}
