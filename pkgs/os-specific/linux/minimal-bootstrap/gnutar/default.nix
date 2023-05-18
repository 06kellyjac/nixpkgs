{ lib
, runCommand
, fetchurl
, tinycc
, gnumake
, getLBFiles

, gnutar
}:
let
  pname = "gnutar";
  version = "1.12";

  src = fetchurl {
    url = "mirror://gnu/tar/tar-${version}.tar.gz";
    sha256 = "02m6gajm647n8l9a5bnld6fnbgdpyi4i3i83p7xcwv0kif47xhy6";
  };

  lbFiles = getLBFiles gnutar.passthru.lbRequirements;

  # stub getdate() that always returns 0
  getdate_stub_c = lbFiles.getdate_stub_c;

  # stat is deliberately hacked to be lstat.
  # In src/system.h tar already defines lstat to be stat
  # since S_ISLNK is not defined in mes C library
  # Hence, we can't use something like #define lstat(a,b) _lstat(a,b)
  # to have separate stat and lstat functions.
  # Thus here we break tar with --dereference option but we don't use
  # this option in live-bootstrap.
  stat_override_c = lbFiles.stat_override_c;
in
runCommand "${pname}-${version}" {
  inherit pname version;

  nativeBuildInputs = [
    tinycc
    gnumake
  ];

  # Thanks to the live-bootstrap project!
  # See https://github.com/fosslinux/live-bootstrap/blob/1bc4296091c51f53a5598050c8956d16e945b0f5/sysa/tar-1.12/tar-1.12.kaem
  passthru.lbRequirements = {
    commit = "1bc4296091c51f53a5598050c8956d16e945b0f5";
    files = let prefix = "sysa/tar-${version}"; in {
      makefile = "${prefix}/mk/main.mk";
      getdate_stub_c = "${prefix}/files/getdate_stub.c";
      stat_override_c = "${prefix}/files/stat_override.c";
    };
  };

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
  cp ${lbFiles.makefile} Makefile
  cp ${getdate_stub_c} lib/getdate_stub.c
  catm src/create.c.new ${stat_override_c} src/create.c
  cp src/create.c.new src/create.c

  # Build
  make

  # Check
  ./tar --version

  # Install
  mkdir -p ''${out}/bin
  cp tar ''${out}/bin
  chmod 555 ''${out}/bin/tar
''
