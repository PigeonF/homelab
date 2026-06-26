{ lib, inputs, ... }:
{
  config = {
    boot = {
      loader = {
        grub = {
          enable = lib.mkDefault false;
        };
        systemd-boot = {
          enable = lib.mkDefault true;
        };
      };
      tmp = {
        cleanOnBoot = lib.mkDefault true;
      };
      zfs = {
        # TODO(PigeonF): Remove in 26.11
        forceImportRoot = false;
      };
    };
    networking = {
      useHostResolvConf = lib.mkOverride 900 false;
      useNetworkd = lib.mkDefault true;
      useDHCP = lib.mkDefault false;
      nftables = {
        enable = lib.mkDefault true;
      };
    };
    nix = {
      settings = {
        extra-experimental-features = [
          "flakes"
          "nix-command"
        ];
      };
    };
    nixpkgs = {
      overlays = [
        # For patched gitlab-runner
        inputs.self.overlays.patchedPackages
        inputs.self.overlays.homelabPackages
      ];
    };
    services = {
      openssh = {
        authorizedKeysInHomedir = lib.mkDefault false;
        extraConfig = ''
          AcceptEnv LANG LANGUAGE LC_*
          AcceptEnv COLORTERM TERM TERM_*
        '';
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
      resolved = {
        enable = lib.mkDefault true;
        settings = {
          Resolve = {
            LLMNR = lib.mkDefault false;
            MulticastDNS = lib.mkDefault false;
          };
        };
      };
      timesyncd = {
        enable = lib.mkDefault true;
      };
      userborn = {
        enable = lib.mkDefault true;
      };
    };
    systemd = {
      enableStrictShellChecks = lib.mkDefault true;
      services = {
        systemd-networkd = {
          stopIfChanged = lib.mkDefault false;
        };
        systemd-resolved = {
          stopIfChanged = lib.mkDefault false;
        };
      };
    };
  };
}
