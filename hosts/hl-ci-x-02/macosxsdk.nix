{
  fetchzip,
  ...
}:

let
  version = "11.3";
in
fetchzip {
  url = "https://github.com/phracker/MacOSX-SDKs/releases/download/${version}/MacOSX${version}.sdk.tar.xz";
  hash = "sha256-BoFWhRSHaD0j3dzDOFtGJ6DiRrdzMJhkjxztxCluFKo=";
}
