{ lib
, runCommand
, fetchurl
, tinycc
, gnumake
, gnupatch
, getLBFiles

, coreutils
}:
let
  pname = "coreutils";
  version = "5.0";

  src = fetchurl {
    url = "mirror://gnu/coreutils/coreutils-${version}.tar.gz";
    sha256 = "10wq6k66i8adr4k08p0xmg87ff4ypiazvwzlmi7myib27xgffz62";
  };

  lbFiles = getLBFiles coreutils.passthru.lbRequirements;

  patches = with lbFiles; [
    # modechange.h uses functions defined in sys/stat.h, so we need to move it to
    # after sys/stat.h include.
    modechange_patch
    # mbstate_t is a struct that is required. However, it is not defined by mes libc.
    mbstate_patch
    # strcoll() does not exist in mes libc, change it to strcmp.
    ls-strcmp_patch
    # getdate.c is pre-compiled from getdate.y
    # At this point we don't have bison yet and in any case getdate.y does not
    # compile when generated with modern bison.
    touch-getdate_patch
    # touch: add -h to change symlink timestamps, where supported
    touch-dereference_patch
    # strcoll() does not exist in mes libc, change it to strcmp.
    expr-strcmp_patch
    # strcoll() does not exist in mes libc, change it to strcmp.
    # hard_LC_COLLATE is used but not declared when HAVE_SETLOCALE is unset.
    sort-locale_patch
  ];
in
runCommand "${pname}-${version}" {
  inherit pname version;

  nativeBuildInputs = [
    tinycc
    gnumake
    gnupatch
  ];

  # Thanks to the live-bootstrap project!
  # See https://github.com/fosslinux/live-bootstrap/blob/e86db47b6ee40d68e26866dd15e8637f64d6d778/sysa/coreutils-5.0/coreutils-5.0.kaem
  passthru.lbRequirements = {
    commit = "e86db47b6ee40d68e26866dd15e8637f64d6d778";
    files = let prefix = "sysa/${pname}-${version}"; in {
      makefile = "${prefix}/mk/main.mk";
      modechange_patch = "${prefix}/patches/modechange.patch";
      mbstate_patch = "${prefix}/patches/mbstate.patch";
      ls-strcmp_patch = "${prefix}/patches/ls-strcmp.patch";
      touch-getdate_patch = "${prefix}/patches/touch-getdate.patch";
      touch-dereference_patch = "${prefix}/patches/touch-dereference.patch";
      expr-strcmp_patch = "${prefix}/patches/expr-strcmp.patch";
      sort-locale_patch = "${prefix}/patches/sort-locale.patch";
    };
  };

  meta = with lib; {
    description = "The GNU Core Utilities";
    homepage = "https://www.gnu.org/software/coreutils";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ emilytrau ];
    platforms = platforms.unix;
  };
} ''
  # Unpack
  ungz --file ${src} --output coreutils.tar
  untar --file coreutils.tar
  rm coreutils.tar
  cd coreutils-${version}

  # Patch
  ${lib.concatMapStringsSep "\n" (f: "patch -Np0 -i ${f}") patches}

  # Configure
  catm config.h
  cp lib/fnmatch_.h lib/fnmatch.h
  cp lib/ftw_.h lib/ftw.h
  cp lib/search_.h lib/search.h
  rm src/dircolors.h

  # Build
  make -f ${lbFiles.makefile} PREFIX=''${out}

  # Check
  ./src/echo "Hello coreutils!"

  # Install
  ./src/mkdir -p ''${out}/bin
  make -f ${lbFiles.makefile} install PREFIX=''${out}
''
