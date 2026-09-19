{
  config,
  dotfiles ? null,
  lib,
  nixpkgs,
  pkgs,
  self,
  ...
}:
{
  config = {
    nix = {
      channel = {
        enable = lib.mkDefault false;
      };
      daemonCPUSchedPolicy = lib.mkDefault "batch";
      daemonIOSchedClass = lib.mkDefault "idle";
      daemonIOSchedPriority = lib.mkDefault 7;
      optimise = {
        automatic = lib.mkDefault (!config.boot.isContainer);
      };
      registry = {
        nixpkgs = lib.mkIf (!config.nixpkgs.flake.setFlakeRegistry) {
          flake = lib.mkDefault nixpkgs;
        };
        self = {
          flake = lib.mkDefault self;
        };
        dotfiles = lib.optionalAttrs (dotfiles != null) {
          flake = lib.mkDefault dotfiles;
        };
      };
      settings = {
        # nspawn containers do not have enough UIDs assigned for this to work.
        # https://git.lix.systems/lix-project/lix/issues/387#issuecomment-16134
        auto-allocate-uids = lib.mkDefault (!config.boot.isNspawnContainer);
        # download-buffer-size = 512 * 1024 * 1024;
        extra-experimental-features = [
          "auto-allocate-uids"
          "cgroups"
          "flakes"
          "nix-command"
        ];
        sandbox = lib.mkDefault true;
        store = lib.mkDefault "daemon";
        system-features = [ "uid-range" ];
        trusted-users = [ "@wheel" ];
        use-cgroups = lib.mkDefault (!config.boot.isNspawnContainer);
        use-xdg-base-directories = lib.mkDefault true;
      };
    };
    systemd = {
      services = {
        nix-daemon = {
          serviceConfig = {
            # NOTE(PigeonF): I forgot which nix issue this belongs to, but without it I get an endlessly forking nix-daemon
            ExecStart =
              if config.boot.isNspawnContainer then
                let
                  start-nix-daemon = pkgs.writeShellApplication {
                    name = "start-nix-daemon";
                    text = ''
                      ${lib.getExe' pkgs.util-linux "mount"} proc -t proc /proc
                      exec -a nix-daemon ${lib.getExe' config.nix.package "nix-daemon"} --daemon --store local
                    '';
                  };
                in
                [
                  ""
                  "${lib.getExe' pkgs.util-linux "unshare"} -m ${lib.getExe start-nix-daemon}"
                ]
              else
                [
                  ""
                  "${lib.getExe' config.nix.package "nix-daemon"} --daemon --store local"
                ];
          };
        };
      };
    };
  };
}
