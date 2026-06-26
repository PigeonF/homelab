{ pkgs, ... }:
let
  fetchWinSDK = pkgs.callPackage ./fetch.nix { };
in
fetchWinSDK {
  crt = "14.44.17.14";
  sdk = "10.0.26100";
  hash = "sha256-Xq0kGxDwR6ileE6HFHaKtj7P8eDLoYtDnCvlK/Ew0/s=";
}
