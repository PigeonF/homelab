{
  lib,
  socat,
  writeShellApplication,
  ...
}:
writeShellApplication {
  name = "systemd-vmspawn-ssh-proxy";
  text = ''
    name=''${1:?Expected two arguments: name and port}
    port=''${2:-22}

    cid=$(machinectl show "$name" -p VSockCID --value)
    exec ${lib.getExe socat} STDIO "VSOCK-CONNECT:$cid:$port"
  '';
  meta = {
    mainProgram = "systemd-vmspawn-ssh-proxy";
  };
}
