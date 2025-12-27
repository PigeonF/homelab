# Configure systemd-boot as the bootloader
{ config, ... }:
{
  config = {
    assertions = [
      {
        assertion = !config.boot.isContainer;
        message = "container should not have bootloader enabled";
      }
    ];
    boot = {
      loader = {
        grub = {
          enable = false;
        };
        systemd-boot = {
          enable = true;
          configurationLimit = 10;
          consoleMode = "auto";
          editor = false;
        };
        timeout = 3;
      };
      tmp = {
        cleanOnBoot = true;
      };
    };

  };
}
