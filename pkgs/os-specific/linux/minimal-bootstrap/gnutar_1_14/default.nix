{ lib
, buildPlatform
, hostPlatform
, runCommand
, fetchurl
, tinycc
, gnumake
, gnused
, coreutils
, gnugrep
, bash
}:
let
  pname = "gnutar";
  # need --strip-path=NUM
  version = "1.14";

  src = fetchurl {
    url = "mirror://gnu/tar/tar-${version}.tar.gz";
    sha256 = "sha256-wXMMqSPBK47YfoV3rpQLD02E1fL0SWZ6c6uDJCvXh8c=";
  };

  # Thanks to the live-bootstrap project!
  # See https://github.com/fosslinux/live-bootstrap/blob/1bc4296091c51f53a5598050c8956d16e945b0f5/sysa/tar-1.12/tar-1.12.kaem
  liveBootstrap = "https://github.com/fosslinux/live-bootstrap/raw/1bc4296091c51f53a5598050c8956d16e945b0f5/sysa/tar-1.12";

  makefile = fetchurl {
    url = "${liveBootstrap}/mk/main.mk";
    sha256 = "0iqidqns4j452pcsh9zr3pbgr2y128xxrl1fz7v1rj7d5zhij1h4";
  };

  # stub getdate() that always returns 0
  getdate_stub_c = fetchurl {
    url = "${liveBootstrap}/files/getdate_stub.c";
    sha256 = "0i0j6ymksqf6ip82yqw7j4qwzyc580j2d7wsdf41p8nvg9dmaw4n";
  };

  # stat is deliberately hacked to be lstat.
  # In src/system.h tar already defines lstat to be stat
  # since S_ISLNK is not defined in mes C library
  # Hence, we can't use something like #define lstat(a,b) _lstat(a,b)
  # to have separate stat and lstat functions.
  # Thus here we break tar with --dereference option but we don't use
  # this option in live-bootstrap.
  stat_override_c = fetchurl {
    url = "${liveBootstrap}/files/stat_override.c";
    sha256 = "1ald02j1c15nhs865bwl17lqcy45mrr8n5j0bhhnxkah1bnhimrz";
  };
in
bash.runCommand "${pname}-${version}" {
  inherit pname version;

  nativeBuildInputs = [
    tinycc
    gnumake
    gnused
    coreutils
    gnugrep
  ];

  meta = with lib; {
    description = "GNU implementation of the `tar' archiver";
    homepage = "https://www.gnu.org/software/tar";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ emilytrau ];
    mainProgram = "tar";
    platforms = platforms.unix;
  };
} ''
  # Unpack
  ungz --file ${src} --output tar.tar
  untar --file tar.tar
  rm tar.tar
  build=''${NIX_BUILD_TOP}/tar-${version}
  cd ''${build}

  # Configure
  export CC="tcc -static -DMB_LEN_MAX"
  export LD="tcc"
  bash configure \
    --build=${buildPlatform.config} \
    --host=${hostPlatform.config} \
    --disable-nls \
    --disable-dependency-tracking \
    --prefix=''${out}

  # Build
  make

  # Check
  ./tar --version

  # Install
  mkdir -p ''${out}/bin
  cp tar ''${out}/bin
  chmod 555 ''${out}/bin/tar
''
