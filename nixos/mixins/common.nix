{ lib, ... }:
{
  documentation = {
    dev = {
      enable = true;
    };
    doc = {
      enable = false;
    };
    info = {
      enable = false;
    };
    nixos = {
      enable = false;
    };
  };
  environment = {
    defaultPackages = lib.mkDefault [ ];
    ldso32 = null;
    stub-ld = {
      enable = false;
    };
  };
  security = {
    sudo = {
      execWheelOnly = true;
      extraConfig = ''
        Defaults lecture = never
      '';
    };
  };
  services = {
    userborn = {
      enable = true;
    };
  };
  systemd = {
    enableStrictShellChecks = true;
  };
  system = {
    tools = {
      nixos-enter = {
        enable = false;
      };
      nixos-generate-config = {
        enable = false;
      };
      nixos-install = {
        enable = false;
      };
    };
  };
  users = {
    mutableUsers = false;
  };
}
