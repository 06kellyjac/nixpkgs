{
  lib,
  autoAddDriverRunpath,
  cmake,
  fetchFromGitHub,
  installShellFiles,
  nix-update-script,
  stdenv,

  config,
  cudaSupport ? config.cudaSupport,
  cudaPackages ? { },

  rocmSupport ? config.rocmSupport,
  rocmPackages ? { },
  rocmGpuTargets ? rocmPackages.clr.localGpuTargets or rocmPackages.clr.gpuTargets,

  rocmStrixHaloOptimizations ? false,

  cpuArchDynamicDispatch ? true,

  openclSupport ? false,
  clblast,

  blasSupport ? builtins.all (x: !x) [
    cudaSupport
    metalSupport
    openclSupport
    rocmSupport
    vulkanSupport
  ],
  blas,

  fetchNpmDeps,
  nodejs_latest,
  npmHooks,

  pkg-config,
  metalSupport ? stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isAarch64 && !openclSupport,
  vulkanSupport ? false,
  openssl,
  audio-cpp,
  shaderc,
  vulkan-headers,
  vulkan-loader,
  spirv-headers,
  ninja,
}:

let
  # It's necessary to consistently use backendStdenv when building with CUDA support,
  # otherwise we get libstdc++ errors downstream.
  # cuda imposes an upper bound on the gcc version
  effectiveStdenv = if cudaSupport then cudaPackages.backendStdenv else stdenv;
  inherit (lib)
    cmakeBool
    cmakeFeature
    optionals
    optionalString
    ;

  cudaBuildInputs = with cudaPackages; [
    cccl # <nv/target>

    # A temporary hack for reducing the closure size, remove once cudaPackages
    # have stopped using lndir: https://github.com/NixOS/nixpkgs/issues/271792
    cuda_cudart
    libcublas
  ];

  rocmBuildInputs = with rocmPackages; [
    clr
    hipblas
    rocblas
  ];

  vulkanBuildInputs = [
    shaderc
    vulkan-headers
    vulkan-loader
  ];
in
effectiveStdenv.mkDerivation (finalAttrs: {
  pname = "audio-cpp";
  version = "0.7.0";

  src = fetchFromGitHub {
    owner = "0xShug0";
    repo = "audio.cpp";
    # tag = "release-${finalAttrs.version}";
    rev = "aec444c6007fbd3b5f57074c60875eb4e54ef8f1"; # need the inbuilt model management
    hash = "sha256-iU0VUyCEvwJCzIrigzdAfUiChCwFBTUUogM5S599cG8=";
    leaveDotGit = true;
    postFetch = ''
      git -C "$out" rev-parse --short HEAD > $out/COMMIT
      find "$out" -name .git -print0 | xargs -0 rm -rf
    '';
  };

  patches = [
    ./models-dir.patch
  ];

  nativeBuildInputs = [
    cmake
    installShellFiles
    ninja
    pkg-config
    spirv-headers
  ]
  ++ optionals cudaSupport [
    cudaPackages.cuda_nvcc
    autoAddDriverRunpath
  ];

  buildInputs =
    optionals cudaSupport cudaBuildInputs
    ++ optionals openclSupport [ clblast ]
    ++ optionals rocmSupport rocmBuildInputs
    ++ optionals blasSupport [ blas ]
    ++ optionals vulkanSupport vulkanBuildInputs
    ++ [ openssl ];

  preConfigure = ''
    prependToVar cmakeFlags "-DLLAMA_BUILD_COMMIT:STRING=$(cat COMMIT)"
    # substituteInPlace CMakeLists.txt --replace-fail "BUILD_SHARED_LIBS OFF" "BUILD_SHARED_LIBS ON"
  '';

  cmakeFlags = [
    (cmakeBool "AUDIOCPP_DEPLOYMENT_BUILD" true) # include model spec documents
    (cmakeBool "GGML_NATIVE" false) # -march=native would make builds non-deterministic
    # (cmakeBool "BUILD_SHARED_LIBS" true)
    (cmakeBool "ENGINE_BUILD_EXAMPLES" false)
    (cmakeBool "ENGINE_BUILD_TESTS" (finalAttrs.finalPackage.doCheck or false))
    (cmakeBool "ENGINE_BUILD_TESTS" false)
    (cmakeBool "ENGINE_ENABLE_CUDA" cudaSupport)
    (cmakeBool "ENGINE_ENABLE_HIP" rocmSupport)
    (cmakeBool "ENGINE_ENABLE_METAL" metalSupport)
    (cmakeBool "ENGINE_VULKAN" vulkanSupport)
    # opt-in to native model management to drop python requirement
    # also required for de-vendoring boringssl
    (cmakeBool "AUDIOCPP_BUILD_NATIVE_MODEL_MANAGER" true)
    # de-vendor boringssl
    (cmakeBool "AUDIOCPP_USE_SYSTEM_OPENSSL" true)
  ]
  ++ optionals cpuArchDynamicDispatch [
    # Build all CPU backend variants for runtime dynamic dispatch.
    # This avoids illegal instructions on older CPUs and gives optimal performance
    # on newer ones without needing separate builds.
    # Enabling AVX2 can make CPU inference 13x faster compared to NixOS's x86_64 defaults.
    # Note it is not a bug that the CPU variant .so files are placed in `bin/`
    # (as opposed to `lib/`) alongside the executables by upstream's `CMakeLists.txt` design:
    # * https://github.com/ggml-org/llama.cpp/blob/b46812de78f8fbcb6cf0154947e8633ebc78d9ac/ggml/src/CMakeLists.txt#L249-L252
    # * https://github.com/ggml-org/llama.cpp/blob/b46812de78f8fbcb6cf0154947e8633ebc78d9ac/ggml/src/ggml-backend-reg.cpp#L480-L486
    # (cmakeBool "GGML_CPU_ALL_VARIANTS" true)
    # (cmakeBool "GGML_BACKEND_DL" true)
  ]
  ++ optionals cudaSupport [
    (cmakeFeature "CMAKE_CUDA_ARCHITECTURES" cudaPackages.flags.cmakeCudaArchitecturesString)
  ]
  ++ optionals rocmSupport [
    (cmakeFeature "CMAKE_HIP_COMPILER" "${rocmPackages.clr.hipClangPath}/clang++")
    (cmakeFeature "CMAKE_HIP_ARCHITECTURES" (builtins.concatStringsSep ";" rocmGpuTargets))
  ]
  ++ optionals (rocmSupport && rocmStrixHaloOptimizations) [
    (cmakeBool "ENGINE_HIP_STRIX_HALO_OPTIMIZATIONS" true)
  ]
  ++ optionals metalSupport [
    (cmakeFeature "CMAKE_C_FLAGS" "-D__ARM_FEATURE_DOTPROD=1")
    (cmakeBool "LLAMA_METAL_EMBED_LIBRARY" true)
  ];

  # the tests are failing as of 2025-08
  doCheck = false;

  postInstall = ''
    mv ./bin $out/bin
  '';

  passthru = {
    tests = lib.optionalAttrs stdenv.hostPlatform.isDarwin {
      metal = audio-cpp.override { metalSupport = true; };
    };
    updateScript = nix-update-script {
      attrPath = "audio-cpp";
      extraArgs = [
        "--version-regex"
        "release-(.*)"
      ];
    };
  };

  meta = {
    description = "Inference of Meta's LLaMA model (and others) in pure C/C++";
    homepage = "https://github.com/ggml-org/llama.cpp";
    license = lib.licenses.mit;
    mainProgram = "audiocpp_cli";
    maintainers = with lib.maintainers; [
      jk
    ];
    platforms = lib.platforms.unix;
    badPlatforms = optionals (cudaSupport || openclSupport) lib.platforms.darwin;
    broken = metalSupport && !effectiveStdenv.hostPlatform.isDarwin;
  };
})
