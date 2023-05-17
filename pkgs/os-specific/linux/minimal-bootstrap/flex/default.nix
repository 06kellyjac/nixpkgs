{ lib
, runCommand
, fetchurl
, tinycc
, gnumake
, gnupatch
, gnused
, coreutils
, bash
, heirloom-devtools
, live-bootstrap-files
, bootstrap ? false
, flex ? null
}:
assert bootstrap -> flex != null;
let
  pname = "flex" + lib.optionalString bootstrap "-boot";
  version = "2.5.11";

  src = fetchurl {
    url = "http://download.nust.na/pub2/openpkg1/sources/DST/flex/flex-${version}.tar.gz";
    sha256 = "129nsxxhn5gzsmwfy45xri8iw4r6h9sy79l9zxk8v8swyf8bhydw";
  };

  # Thanks to the live-bootstrap project!
  # See https://github.com/fosslinux/live-bootstrap/blob/1bc4296091c51f53a5598050c8956d16e945b0f5/sysa/flex-2.5.11
  liveBootstrap = live-bootstrap-files.packageFiles {
    pname = "flex";
    inherit version;
    parent = "sysa";
  };

  makefile = liveBootstrap."mk/main.mk";

  scan_lex_l = liveBootstrap."files/scan.lex.l";

  patches = [
    # Comments are unsupported by our flex
    liveBootstrap."patches/scan_l.patch"
    # yyin has an odd redefinition error in scan.l, so we ensure that we don't
    # acidentally re-declare it.
    liveBootstrap."patches/yyin.patch"
  ];
in
runCommand "${pname}-${version}" {
  inherit pname version;

  nativeBuildInputs =
    # Order is important to override "lex" from heirloom-devtools after boot stage
    lib.optional (!bootstrap) flex
    ++ [
      tinycc
      gnumake
      gnupatch
      gnused
      coreutils
      bash
      heirloom-devtools
    ];

  meta = with lib; {
    description = "GNU Bourne-Again Shell, the de facto standard shell on Linux";
    homepage = "https://www.gnu.org/software/bash";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ emilytrau ];
    platforms = platforms.unix;
  };
} ''
  # Unpack
  ungz --file ${src} --output flex.tar
  untar --file flex.tar
  rm flex.tar
  build=''${NIX_BUILD_TOP}/flex-${version}
  cd ''${build}

  # Patch
  ${lib.concatLines (map (f: "patch -Np0 -i ${f}") patches)}

  # Configure
  cp ${makefile} Makefile
  # Replace hardcoded /bin/sh with bash in PATH
  sed -i "s|/bin/sh|sh|g" Makefile
  cp ${scan_lex_l} scan.lex.l
  touch config.h
  rm parse.c parse.h scan.c skel.c

  # Build
  make LDFLAGS="-static -L${heirloom-devtools}/lib"

  # Check
  ./flex --version

  # Install
  make install PREFIX=''${out}
''
