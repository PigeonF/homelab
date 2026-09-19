{
  lib,
  writeShellApplication,
  ...
}:
let
  parameters = ''
    tarball=''${1?Missing required parameter: tarball}
    name=''${2?Missing required parameter: name}
    limit=''${3:-none}
  '';
  import-machine = writeShellApplication {
    name = "import-machine";
    text = parameters + ''
      importctl import-tar --class=machine --force "$tarball" "$name"
      machinectl set-limit "$name" "$limit"
    '';
    meta = {
      mainProgram = "import-machine";
    };
  };
  deploy-nspawn = writeShellApplication {
    name = "deploy-nspawn";
    text = parameters + ''
      ${lib.getExe import-machine} "$tarball" "$name" "$limit"
      systemctl reload-or-restart "systemd-nspawn@$name"
    '';
    meta = {
      mainProgram = "deploy-nspawn";
    };
  };
  deploy-vmspawn = writeShellApplication {
    name = "deploy-vmspawn";
    text = parameters + ''
      ${lib.getExe import-machine} "$tarball" "$name" "$limit"
      systemctl reload-or-restart "systemd-vmspawn@$name"
    '';
    meta = {
      mainProgram = "deploy-vmspawn";
    };
  };
  createWrapper =
    { type, pkg }:
    {
      name,
      base,
      limit ? "none",
    }:
    writeShellApplication {
      name = "deploy-${type}-${name}";
      text = ''
        exec ${lib.getExe pkg} "${base}/${base.passthru.filePath}" "${name}" "${limit}"
      '';
      meta.mainProgram = "deploy-${type}-${name}";
    };
in
{
  inherit import-machine;

  deploy-nspawn = deploy-nspawn // {
    passthru.createWrapper = createWrapper {
      type = "nspawn";
      pkg = deploy-nspawn;
    };
  };

  deploy-vmspawn = deploy-vmspawn // {
    passthru.createWrapper = createWrapper {
      type = "vmspawn";
      pkg = deploy-vmspawn;
    };
  };
}
