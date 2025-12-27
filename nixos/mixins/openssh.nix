{
  security = {
    sudo = {
      extraConfig = ''
        Defaults:root,%whell env_keep+=SSH_AUTH_SOCK
      '';
    };
  };
  services = {
    openssh = {
      enable = true;
      authorizedKeysInHomedir = false;
      extraConfig = ''
        AcceptEnv LANG LANGUAGE LC_*
        AcceptEnv COLORTERM TERM TERM_*
      '';
      settings = {
        KbdInteractiveAuthentication = false;
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
        PasswordAuthentication = false;
        X11Forwarding = false;
        UseDns = false;
        StreamLocalBindUnlink = true;
      };
    };
  };
}
