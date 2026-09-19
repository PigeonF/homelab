{
  lib,
  pkgs,
  ...
}:
let
  createWrapper = {
    __functor =
      self:
      {
        base,
        name,
        limit ? "none",
      }:
      let
        program = "deploy-" + self.type + "-" + name;
      in
      pkgs.writeShellApplication {
        name = program;
        text = ''
          #!${pkgs.runtimeShell}
          exec ${lib.getExe self.pkg} "${base}/${base.passthru.filePath}" "${name}" "${limit}"
        '';
        meta = {
          mainProgram = program;
        };
      };
  };
  parameters = ''
    tarball=''${1?Missing required parameter: tarball}
    name=''${2?Missing required parameter: name}
    limit=''${3:-none}
  '';
in
rec {
  import-machine = pkgs.writeShellApplication {
    name = "import-machine";
    text = parameters + ''
      importctl import-tar --class=machine --force "$tarball" "$name"
      machinectl set-limit "$name" "$limit"
    '';
    meta = {
      mainProgram = "import-machine";
    };
  };
  deploy-nspawn = pkgs.writeShellApplication {
    name = "deploy-nspawn";
    text = parameters + ''
      ${lib.getExe import-machine} "$tarball" "$name" "$limit"
      systemctl reload-or-restart "systemd-nspawn@$name"
    '';
    meta = {
      mainProgram = "deploy-nspawn";
    };
    passthru = {
      createWrapper = createWrapper // {
        type = "nspawn";
        pkg = deploy-nspawn;
      };
    };
  };
  deploy-vmspawn = pkgs.writeShellApplication {
    name = "deploy-vmspawn";
    text = parameters + ''
      ${lib.getExe import-machine} "$tarball" "$name" "$limit"
      systemctl reload-or-restart "systemd-vmspawn@$name"
    '';
    meta = {
      mainProgram = "deploy-vmspawn";
    };
    passthru = {
      createWrapper = createWrapper // {
        type = "vmspawn";
        pkg = deploy-vmspawn;
      };
    };
  };
}
