{ dotfiles, ... }:
{
  home-manager = {
    users = {
      reviewer = {
        imports = [ dotfiles.homeModules.reviewer ];
        dotfiles = {
          dotter = {
            extraArgs = [
              "--local-config"
              ".dotter/hl-dev-x-02.toml"
              "--cache-file"
              "/tmp/dotter-cache.toml"
              "--cache-directory"
              "/tmp/dotter-cache"
            ];
          };
        };
        home = {
          file = {
            "git/github.com/PigeonF/dotfiles" = {
              source = dotfiles;
            };
          };
        };
      };
    };
  };
  users = {
    users = {
      reviewer = {
        autoSubUidGidRange = true;
        extraGroups = [
          "wheel"
          "docker"
        ];
        initialHashedPassword = "$y$j9T$EZbEP6uUMPv8ByEvL7duB0$QZWlxuBZjG5wAMAlxk9g.tRPdTu0WIMG3W7xMjTzPK1";
        isNormalUser = true;
      };
    };
  };
}
