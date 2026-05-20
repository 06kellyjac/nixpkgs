{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  openssl,
  httplib,
  nlohmann_json,

  rocmPackages ? { },
  rocmGpuTargets ? rocmPackages.clr.localGpuTargets or rocmPackages.clr.gpuTargets,
}:

let
  rocmBuildInputs = with rocmPackages; [
    clr
    hipblas
    rocblas
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "qwen3-tts-cpp";
  version = "0-unstable-2026-04-21";

  src = fetchFromGitHub {
    owner = "khimaros";
    repo = "qwen3-tts.cpp";
    rev = "2a41916e7c5ff20b51359f4f806acb790753d0fd";
    hash = "sha256-pBJOtC6I/hwmdQK6sEfvEvcxAdE8Qo2K+n50Hz/m61s=";
    fetchSubmodules = true;
  };

  patches = [
    ./0001-local-deps.patch
    ./0002-use-updated-httplib.patch
    ./0003-predefined-samples-server-icl4.patch
  ];

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = rocmBuildInputs ++ [
    openssl
    httplib
    nlohmann_json
  ];

  cmakeFlags = [
    (lib.cmakeBool "GGML_HIP" true)
    (lib.cmakeFeature "CMAKE_HIP_COMPILER" "${rocmPackages.clr.hipClangPath}/clang++")
    (lib.cmakeFeature "CMAKE_HIP_ARCHITECTURES" (builtins.concatStringsSep ";" rocmGpuTargets))
  ];

  meta = {
    description = "";
    homepage = "https://github.com/khimaros/qwen3-tts.cpp";
    license = lib.licenses.mit; # FIXME: nix-init did not find a license
    maintainers = with lib.maintainers; [ ];
    mainProgram = "qwen3-tts-cpp";
    platforms = lib.platforms.all;
  };
})
