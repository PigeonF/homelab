{ lib, inputs, ... }:
{
  boot = {
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
  nixpkgs = {
    overlays = [
      # For patched gitlab-runner
      inputs.self.overlays.patchedPackages
    ];
  };
  services = {
    resolved = {
      enable = lib.mkDefault true;
      settings = {
        Resolve = {
          LLMNR = lib.mkDefault false;
          MulticastDNS = lib.mkDefault false;
        };
      };
    };
    userborn = {
      enable = lib.mkDefault true;
    };
  };
  systemd = {
    enableStrictShellChecks = lib.mkDefault true;
  };
}
