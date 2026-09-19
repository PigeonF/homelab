{ lib, ... }:
{
  config = {
    services = {
      openssh = {
        authorizedKeysInHomedir = lib.mkDefault false;
        settings = {
          KbdInteractiveAuthentication = lib.mkDefault false;
          KexAlgorithms = [
            "curve25519-sha256"
            "curve25519-sha256@libssh.org"
            "diffie-hellman-group16-sha512"
            "diffie-hellman-group18-sha512"
            "sntrup761x25519-sha512@openssh.com"
          ];
          Macs = [
            "hmac-sha2-512-etm@openssh.com"
            "hmac-sha2-256-etm@openssh.com"
            "umac-128-etm@openssh.com"
          ];
          PasswordAuthentication = lib.mkDefault false;
          X11Forwarding = lib.mkDefault false;
          UseDns = lib.mkDefault false;
          StreamLocalBindUnlink = lib.mkDefault true;
        };
      };
    };
  };
}
