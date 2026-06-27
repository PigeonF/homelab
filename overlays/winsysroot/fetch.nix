{
  stdenv,
  xwin,
  ...
}:

{
  crt,
  sdk,
  hash,
}:

stdenv.mkDerivation {
  pname = "Win-Sysroot";
  version = "crt-${crt}-sdk-${sdk}";
  doCheck = false;
  dontUnpack = true;
  dontFixup = true;
  nativeBuildInputs = [ xwin ];
  buildCommand = ''
    runHook preBuild

    xwin --timeout=120 --http-retry=3 --accept-license --arch=x86 --arch=x86_64 --arch=aarch64 --sdk-version="${sdk}" --crt-version="${crt}" splat --copy --preserve-ms-arch-notation --output="$out"

    runHook postBuild
  '';
  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
  outputHash = hash;
}
