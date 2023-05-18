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
}:
let
  pname = "musl";
  version = "1.1.24";

  src = fetchurl {
    url = "https://musl.libc.org/releases/musl-${version}.tar.gz";
    sha256 = "18r2a00k82hz0mqdvgm7crzc7305l36109c0j9yjmkxj2alcjw0k";
  };

  # Thanks to the live-bootstrap project!
  # See https://github.com/fosslinux/live-bootstrap/blob/1bc4296091c51f53a5598050c8956d16e945b0f5/sysa/musl-1.1.24
  liveBootstrap = "https://github.com/fosslinux/live-bootstrap/raw/1bc4296091c51f53a5598050c8956d16e945b0f5/sysa/musl-1.1.24";
  patches = [
    (fetchurl {
      url = "${liveBootstrap}/patches/avoid_set_thread_area.patch";
      sha256 = "1yxhjxqm1x6i5jrmiipbanasbjzs0nvqn2ni3ccs7z1qg5jw3ijf";
    })
    (fetchurl {
      url = "${liveBootstrap}/patches/avoid_sys_clone.patch";
      sha256 = "0gij41g83pf13vjw9608v42j4q3acc9y3l6pqndwkv3rhbmqg6gx";
    })
    (fetchurl {
      url = "${liveBootstrap}/patches/fenv.patch";
      sha256 = "0cl98hvz9f32n37bk1pg0sl8kd6k6sh4lb4qbc4y0xbqhf74didw";
    })
    (fetchurl {
      url = "${liveBootstrap}/patches/makefile.patch";
      sha256 = "1g6555dfgvl1k3a4gn77fcd83klqp4d8c8c25hfv3ci70l29hy6k";
    })
    (fetchurl {
      url = "${liveBootstrap}/patches/musl_weak_symbols.patch";
      sha256 = "1zg2l17zg6s1ddkry5bpqks1q9haz2j7nwidr9pfz994wpcmmpzx";
    })
    (fetchurl {
      url = "${liveBootstrap}/patches/set_thread_area.patch";
      sha256 = "1kdcjkyqsm6h31wnyiymhnd52063w8d551a8zwbiwjyinslmi1j4";
    })
    (fetchurl {
      url = "${liveBootstrap}/patches/sigsetjmp.patch";
      sha256 = "1xg0r83dx98cp1m90m5kq8h7b6m7msldsxxgvvr9ag3kzmx81pf1";
    })
    (fetchurl {
      url = "${liveBootstrap}/patches/va_list.patch";
      sha256 = "1y7fmkzmrpq46w182crc4s9nb8fa0axqsvz547q2s2lqbwi0qrsj";
    })

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
