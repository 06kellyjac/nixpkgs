{
  lib,
  torch,
  symlinkJoin,
  buildPythonPackage,
  fetchFromGitHub,
  cmake,

  # build-system
  scikit-build-core,
  setuptools,

  # dependencies
  scipy,

  gpuTargets ? [ ],
}:

let
  pname = "bitsandbytes";
  version = "0.47.0";

  inherit (torch) cudaPackages cudaSupport rocmPackages rocmSupport;
  inherit (cudaPackages) cudaMajorMinorVersion;
  rocmMajorMinorVersion = lib.versions.majorMinor rocmPackages.rocm-core.version;

  cudaMajorMinorVersionString = lib.replaceStrings [ "." ] [ "" ] cudaMajorMinorVersion;

  rocmMajorMinorVersionString = lib.replaceStrings [ "." ] [ "" ] rocmMajorMinorVersion;

  # Create the gpuTargetString.
  gpuTargetString = lib.strings.concatStringsSep ";" (
    if gpuTargets != [ ] then
      # If gpuTargets is specified, it always takes priority.
      gpuTargets
    else if rocmSupport then
      rocmPackages.clr.gpuTargets
    else
      throw "No GPU targets specified"
  );

  # NOTE: torchvision doesn't use cudnn; torch does!
  #   For this reason it is not included.
  cuda-common-redist = with cudaPackages; [
    (lib.getDev cuda_cccl) # <thrust/*>
    (lib.getDev libcublas) # cublas_v2.h
    (lib.getLib libcublas)
    libcurand
    libcusolver # cusolverDn.h
    (lib.getDev libcusparse) # cusparse.h
    (lib.getLib libcusparse) # cusparse.h
    (lib.getDev cuda_cudart) # cuda_runtime.h cuda_runtime_api.h
  ];

  cuda-native-redist = symlinkJoin {
    name = "cuda-native-redist-${cudaMajorMinorVersion}";
    paths =
      with cudaPackages;
      [
        (lib.getDev cuda_cudart) # cuda_runtime.h cuda_runtime_api.h
        (lib.getLib cuda_cudart)
        (lib.getStatic cuda_cudart)
        cuda_nvcc
      ]
      ++ cuda-common-redist;
  };

  cuda-redist = symlinkJoin {
    name = "cuda-redist-${rocmMajorMinorVersion}";
    paths = cuda-common-redist;
  };

  rocm-common-redist = with rocmPackages; [
    clr
    rocthrust
    rocprim
    hipsparse
    hipblas

    hiprand
    rocrand
    hipblaslt
    # rocblas
    (lib.getDev rocblas) # rocblas/rocblas.h
    (lib.getLib rocblas) # rocblas/rocblas.h
    hipblas-common
    hipcub
  ];

  rocm-native-redist = symlinkJoin {
    name = "rocm-native-redist-${rocmMajorMinorVersion}";
    paths =
      with rocmPackages;
      [
      ]
      ++ rocm-common-redist;
  };

  rocm-redist = symlinkJoin {
    name = "rocm-redist-${rocmMajorMinorVersion}";
    paths = rocm-common-redist;
  };
in
buildPythonPackage {
  inherit pname version;
  pyproject = true;

  src = fetchFromGitHub {
    owner = "bitsandbytes-foundation";
    repo = "bitsandbytes";
    tag = version;
    hash = "sha256-iUAeiNbPa3Q5jJ4lK2G0WvTKuipb0zO1mNe+wcRdnqs=";
  };

  # By default, which library is loaded depends on the result of `torch.cuda.is_available()`.
  # When `cudaSupport` is enabled, bypass this check and load the cuda library unconditionally.
  # Indeed, in this case, only `libbitsandbytes_cuda124.so` is built. `libbitsandbytes_cpu.so` is not.
  # Also, hardcode the path to the previously built library instead of relying on
  # `get_cuda_bnb_library_path(cuda_specs)` which relies on `torch.cuda` too.
  #
  # WARNING: The cuda library is currently named `libbitsandbytes_cudaxxy` for cuda version `xx.y`.
  # This upstream convention could change at some point and thus break the following patch.
  postPatch = lib.optionalString cudaSupport ''
    substituteInPlace bitsandbytes/cextension.py \
      --replace-fail "if cuda_specs:" "if True:" \
      --replace-fail \
        "cuda_binary_path = get_cuda_bnb_library_path(cuda_specs)" \
        "cuda_binary_path = PACKAGE_DIR / 'libbitsandbytes_cuda${cudaMajorMinorVersionString}.so'"
  '' + lib.optionalString rocmSupport ''
    substituteInPlace bitsandbytes/cextension.py \
      --replace-fail "if cuda_specs:" "if True:" \
      --replace-fail \
        "cuda_binary_path = get_cuda_bnb_library_path(cuda_specs)" \
        "cuda_binary_path = PACKAGE_DIR / 'libbitsandbytes_rocm${rocmMajorMinorVersionString}.so'"
  '';

  nativeBuildInputs = [
    cmake
  ]
  ++ lib.optionals cudaSupport [
    cudaPackages.cuda_nvcc
  ]
  ++ lib.optionals rocmSupport [
    rocmPackages.hipcc
    rocmPackages.rocminfo
  ];

  build-system = [
    scikit-build-core
    setuptools
  ];

  buildInputs = lib.optional cudaSupport cuda-redist ++ lib.optional rocmSupport rocm-redist;

  cmakeFlags = [
    (lib.cmakeFeature "COMPUTE_BACKEND" (if cudaSupport then "cuda" else if rocmSupport then "hip" else "cpu"))
  ] ++ lib.optional rocmSupport (lib.cmakeFeature "AMDGPU_TARGETS" "${gpuTargetString}");
  CUDA_HOME = lib.optionalString cudaSupport "${cuda-native-redist}";
  NVCC_PREPEND_FLAGS = lib.optionals cudaSupport [
    "-I${cuda-native-redist}/include"
    "-L${cuda-native-redist}/lib"
  ];
  ROCM_PATH = lib.optionalString rocmSupport "${rocm-native-redist}";

  preBuild = ''
    make -j $NIX_BUILD_CORES
    cd .. # leave /build/source/build
  '';

  dependencies = [
    scipy
    torch
  ];

  doCheck = false; # tests require CUDA and also GPU access

  pythonImportsCheck = [ "bitsandbytes" ];

  meta = {
    description = "8-bit CUDA functions for PyTorch";
    homepage = "https://github.com/bitsandbytes-foundation/bitsandbytes";
    changelog = "https://github.com/bitsandbytes-foundation/bitsandbytes/releases/tag/${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ bcdarwin ];
  };
}
