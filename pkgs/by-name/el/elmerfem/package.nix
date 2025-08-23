{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  gfortran,
  mpi,
  blas,
  liblapack,
  pkg-config,
  libGL,
  libGLU,
  opencascade-occt,
  libsForQt5,
  tbb,
  vtkWithQt5,
  llvmPackages,
}:
stdenv.mkDerivation rec {
  pname = "elmerfem";
  version = "9.0-unstable-2025-05-25";

  src = fetchFromGitHub {
    owner = "elmercsc";
    repo = "elmerfem";
    rev = "2f7360ddf491c34f19fea9a723f340cca0fbe1d4";
    hash = "sha256-2vzIFGh8+YrMxb5px6+aQyTerOAJmHOh2I7eterY6zI=";
  };

  hardeningDisable = [ "format" ];

  nativeBuildInputs = [
    cmake
    gfortran
    pkg-config
    libsForQt5.wrapQtAppsHook
  ];

  buildInputs = [
    mpi
    blas
    liblapack
    libsForQt5.qtbase
    libsForQt5.qtscript
    libsForQt5.qwt
    libGL
    libGLU
    opencascade-occt
    tbb
    vtkWithQt5
  ]
  ++ lib.optional stdenv.cc.isClang llvmPackages.openmp;

  preConfigure = ''
    patchShebangs ./
  '';

  NIX_CFLAGS_COMPILE = "-Wno-error=implicit-function-declaration";

  cmakeFlags = [
    (lib.cmakeFeature "ELMER_INSTALL_LIB_DIR" "${placeholder "out"}/lib")
    (lib.cmakeBool "WITH_OpenMP" true)
    (lib.cmakeBool "WITH_MPI" true)
    (lib.cmakeBool "WITH_QT6" true)
    (lib.cmakeBool "WITH_OCC" true)
    (lib.cmakeBool "WITH_VTK" true)
    (lib.cmakeBool "WITH_ELMERGUI" true)
    (lib.cmakeFeature "CMAKE_INSTALL_LIBDIR" "lib")
    (lib.cmakeFeature "CMAKE_INSTALL_INCLUDEDIR" "include")
    (lib.cmakeFeature "CMAKE_OpenGL_GL_PREFERENCE" "GLVND")
    (lib.cmakeBool "USE_MACOS_PACKAGE_MANAGER" false)
  ];

  meta = with lib; {
    homepage = "https://elmerfem.org";
    description = "Finite element software for multiphysical problems";
    platforms = platforms.unix;
    maintainers = with maintainers; [
      wulfsta
      broke
    ];
    license = licenses.lgpl21;
  };

}
