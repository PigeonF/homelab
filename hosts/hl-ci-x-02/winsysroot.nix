{
  stdenv,
  xwin,
  ...
}:
let
  crt_version = "14.44.17.14";
  sdk_version = "10.0.26100";
  version = "crt-${crt_version}-sdk-${sdk_version}";
in

stdenv.mkDerivation {
  name = "winsysroot";
  inherit version;
  doCheck = false;
  dontUnpack = true;
  dontFixup = true;
  nativeBuildInputs = [ xwin ];
  buildCommand = ''
    runHook preBuild

    xwin --accept-license --arch=x86 --arch=x86_64 --arch=aarch64 --sdk-version="${sdk_version}" --crt-version="${crt_version}" splat --copy --include-debug-libs --preserve-ms-arch-notation --use-winsysroot-style --output="$out"

    runHook postBuild
  '';
  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
  outputHash = "sha256-Xq0kGxDwR6ileE6HFHaKtj7P8eDLoYtDnCvlK/Ew0/s=";
}
