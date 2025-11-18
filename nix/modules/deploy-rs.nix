{
  inputs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.deploy-rs;
  profileOptions = {
    options = {
      path = mkOption {
        type = types.package;
        description = ''
          A derivation containing your required software, and a script to
          activate it in `''${path}/deploy-rs-activate`.
          For ease of use, `deploy-rs` provides a function to easily add the
          required activation script to any derivation.
          Both the working directory and `$PROFILE` will point to `profilePath`
        '';
      };
      profilePath = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          An optional path to where your profile should be installed to, this is
          useful if you want to use a common profile name across multiple users,
          but would have conflicts in your node's profile list.
          This will default to `"/nix/var/nix/profiles/system` if `user` is
          `root` and profile name is `system`, `/nix/var/nix/profiles/per-user/root/$PROFILE_NAME`
          if profile name is different.
          For non-root profiles will default to `/nix/var/nix/profiles/per-user/$USER/$PROFILE_NAME`
          if `/nix/var/nix/profiles/per-user/$USER` already exists, and `''${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles/$PROFILE_NAME`
          otherwise.
        '';
      };
    };
  };
  nodeOptions = {
    options = {
      hostname = mkOption {
        type = types.str;
        description = "The hostname of your server. Can be overridden at invocation time with a flag.";
      };
      profilesOrder = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          An optional list containing the order you want profiles to be deployed.
          This will take effect whenever you run `deploy` without specifying a
          profile, causing it to deploy every profile automatically.
          Any profiles not in this list will still be deployed (in an arbitrary
          order) after those which are listed.
        '';
      };
      profiles = mkOption {
        type = types.attrsOf (
          types.submoduleWith {
            modules = [
              genericOptions
              profileOptions
            ];
          }
        );
      };
    };
  };
  genericOptions = {
    options = {
      sshUser = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          This is the user that deploy-rs will use when connecting. This will
          default to your own username if not specified anywhere.
        '';
      };
      user = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          This is the user that the profile will be deployed to (will use `sudo`
          if not the same as `sshUser`).

          If `sshUser` is specified, this will be the default (though it will
          _not_ default to your own username).
        '';
      };
      sudo = mkOption {
        type = types.str;
        default = "sudo -u";
        description = ''
          Which sudo command to use. Must accept at least two arguments:
          the user name to execute commands as and the rest is the command to
          execute.
        '';
      };
      interactiveSudo = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable interactive sudo (password based sudo). Useful when
          using non-root sshUsers.
        '';
      };
      sshOpts = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          This is an optional list of arguments that will be passed to SSH.
        '';
      };
      fastConnection = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Fast connection to the node. If this is true, copy the whole closure
          instead of letting the node substitute.
        '';
      };
      autoRollback = mkOption {
        type = types.bool;
        default = true;
        description = ''
          If the previous profile should be re-activated if activation fails.
        '';
      };
      magicRollback = mkOption {
        type = types.bool;
        default = true;
        description = ''
          There is a built-in feature to prevent you making changes that might
          render your machine unconnectable or unusable, which works by
          connecting to the machine after profile activation to confirm the
          machine is still available, and instructing the target node to
          automatically roll back if it is not confirmed.
          If you do not disable magicRollback in your configuration, or with the
          CLI flag, you will be unable to make changes to the system which will
          affect you connecting to it (changing SSH port, changing your IP, etc).
        '';
      };
      tempPath = mkOption {
        type = types.path;
        default = "/tmp";
        description = ''
          The path which deploy-rs will use for temporary files, this is
          currently only used by `magicRollback` to create an inotify watcher in
          for confirmations.

          If `magicRollback` is in use, this _must_ be writable by `user`.
        '';
      };
      remoteBuild = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Build the derivation on the target system. Will also fetch all
          external dependencies from the target system's substituters.
        '';
      };
      activationTimeout = mkOption {
        type = types.int;
        default = 240;
        description = ''
          Timeout for profile activation.
        '';
      };
      confirmTimeout = mkOption {
        type = types.int;
        default = 30;
        description = ''
          Timeout for confirmation.
        '';
      };
    };
  };
in
{
  options.deploy-rs = {
    _file = ./deploy-rs.nix;

    deploy-rs = mkOption {
      type = types.unspecified;
      default = inputs.deploy-rs;
      description = ''
        The deploy-rs input
      '';
    };

    flakeCheck = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enables the deploy-rs deploy checks
      '';
    };

    flakeDevShell = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Adds a devshell
      '';
    };

    nodes = mkOption {
      type = types.attrsOf (
        types.submoduleWith {
          modules = [
            genericOptions
            nodeOptions
          ];
        }
      );
      default = { };
      example = lib.literalExpression ''
        {
          some-random-system = {
            hostname = "some-random-system";
            profiles.system = {
              user = "root";
              path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.some-random-system;
            };
          };
        }
      '';
    };

    settings = mkOption {
      type = types.submodule genericOptions;
      default = { };
      example = lib.literalExpression ''
        {
          sshUser = "admin";
          sudo = "doas -u";
        }
      '';
    };
  };

  config =
    let
      # We have to filter null-valued attrs or the deployCheck fails the schema validation.
      deploy = lib.attrsets.filterAttrsRecursive (_: v: v != null) (
        cfg.settings
        // {
          inherit (cfg) nodes;
        }
      );
      inherit (cfg) deploy-rs;
    in
    {
      flake = {
        inherit deploy;
      };

      perSystem =
        { system, pkgs, ... }:
        {
          checks = lib.mkIf (cfg.flakeCheck && deploy-rs.lib ? ${system}) (
            deploy-rs.lib.${system}.deployChecks deploy
          );

          devShells = lib.mkIf cfg.flakeDevShell {
            deploy-rs = pkgs.mkShellNoCC {
              name = "deploy-rs";
              packages = [ deploy-rs.packages.${system}.default ];
            };
          };
        };
    };
}
