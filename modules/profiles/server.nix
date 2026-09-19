{ lib, ... }:
{
  documentation = {
    enable = lib.mkDefault false;
    doc = {
      enable = lib.mkDefault false;
    };
    info = {
      enable = lib.mkDefault false;
    };
    man = {
      enable = lib.mkDefault false;
    };
    nixos = {
      enable = lib.mkDefault false;
    };
  };
  networking = {
    nftables = {
      enable = lib.mkDefault true;
    };
  };
  programs = {
    command-not-found = {
      enable = lib.mkDefault false;
    };
  };
  services = {
    openssh = {
      enable = lib.mkDefault true;
    };
    udisks2 = {
      enable = lib.mkDefault false;
    };
  };
  time = {
    timeZone = lib.mkDefault "UTC";
  };
  xdg = {
    autostart = {
      enable = lib.mkDefault false;
    };
    icons = {
      enable = lib.mkDefault false;
    };
    mime = {
      enable = lib.mkDefault false;
    };
    sounds = {
      enable = lib.mkDefault false;
    };
  };
}
