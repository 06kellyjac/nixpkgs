{ lib
, buildPlatform
, hostPlatform
, runCommand
, fetchurl
, tinycc
, bash
, gnumake
, gnupatch
, gnused
, gnugrep
, coreutils
, getLBFiles

, musl
}:
let
  pname = "musl";
  version = "1.1.24";

  src = fetchurl {
    url = "https://musl.libc.org/releases/musl-${version}.tar.gz";
    sha256 = "18r2a00k82hz0mqdvgm7crzc7305l36109c0j9yjmkxj2alcjw0k";
  };

  lbFiles = getLBFiles coreutils.passthru.lbRequirements;

  patches = [
    lbFiles.avoid_set_thread_area_patch
    lbFiles.avoid_sys_clone_patch
    lbFiles.fenv_patch
    lbFiles.makefile_patch
    lbFiles.musl_weak_symbols_patch
    lbFiles.set_thread_area_patch
    lbFiles.sigsetjmp_patch
    lbFiles.va_list_patch

    # Including this patch causes a compiler error
    #   src/exit/exit.c:12: error: implicit declaration of function '_fini'
    # TODO: figure out why
    # (fetchurl {
    #   url = "${liveBootstrap}/patches/stdio_flush_on_exit.patch";
    #   sha256 = "0f1c3qm306hjj1frnanwcjkggyy0mzy4c9rgdfn3qhbpg1xp6gpz";
    # })
  ];
in
runCommand "${pname}-${version}" {
  inherit pname version;

  nativeBuildInputs = [
    tinycc
    bash
    gnumake
    gnupatch
    gnused
    gnugrep
    coreutils
  ];

  # Thanks to the live-bootstrap project!
  # See https://github.com/fosslinux/live-bootstrap/blob/1bc4296091c51f53a5598050c8956d16e945b0f5/sysa/musl-1.1.24
  passthru.lbRequirements = {
    commit = "1bc4296091c51f53a5598050c8956d16e945b0f5";
    files = let prefix = "sysa/${pname}-${version}"; in {
      avoid_set_thread_area_patch = "${prefix}/patches/avoid_set_thread_area.patch";
      avoid_sys_clone_patch = "${prefix}/patches/avoid_sys_clone.patch";
      fenv_patch = "${prefix}/patches/fenv.patch";
      makefile_patch = "${prefix}/patches/makefile.patch";
      musl_weak_symbols_patch = "${prefix}/patches/musl_weak_symbols.patch";
      set_thread_area_patch = "${prefix}/patches/set_thread_area.patch";
      sigsetjmp_patch = "${prefix}/patches/sigsetjmp.patch";
      va_list_patch = "${prefix}/patches/va_list.patch";
    };
  };

  meta = with lib; {
    description = "An efficient, small, quality libc implementation";
    homepage = "https://musl.libc.org/";
    license = licenses.mit;
    maintainers = with maintainers; [ emilytrau ];
    platforms = platforms.unix;
  };
} ''
  # Unpack
  ungz --file ${src} --output musl.tar
  untar --file musl.tar
  rm musl.tar
  build=''${NIX_BUILD_TOP}/musl-${version}
  cd ''${build}

  # Patch
  ${lib.concatLines (map (f: "patch -Np0 -i ${f}") patches)}
  # tcc does not support complex types
  rm -rf src/complex

  # Configure
  sh ./configure \
    CC="tcc -static" \
    AR="tcc -ar" \
    RANLIB=true \
    CFLAGS="-DSYSCALL_NO_TLS" \
    --disable-shared \
    --prefix=''${out} \
    --build=${buildPlatform.config} \
    --host=${hostPlatform.config}

  # Build
  make

  # Install
  make install INSTALL=install
''
