{ lib
, buildPlatform
, hostPlatform
, fetchurl
, bash
, tinycc
, gnumake
, coreutils
, getLBFiles
, bootstrap ? false, gnused, gnugrep
}:
let
  pname = "gnused" + lib.optionalString bootstrap "-bootstrap";
  # last version that can be compiled with mes-libc
  version = "4.0.9";

  src = fetchurl {
    url = "mirror://gnu/sed/sed-${version}.tar.gz";
    sha256 = "0006gk1dw2582xsvgx6y6rzs9zw8b36rhafjwm288zqqji3qfrf3";
  };

  lbFiles = getLBFiles gnused.passthru.lbRequirements;
in
bash.runCommand "${pname}-${version}" {
  inherit pname version;

  nativeBuildInputs = [
    tinycc
    gnumake
    coreutils
  ] ++ lib.optionals (!bootstrap) [
    gnused
    gnugrep
  ];

  # Thanks to the live-bootstrap project!
  # See https://github.com/fosslinux/live-bootstrap/blob/1bc4296091c51f53a5598050c8956d16e945b0f5/sysa/sed-1.12/sed-1.12.kaem
  passthru.lbRequirements = {
    commit = "1bc4296091c51f53a5598050c8956d16e945b0f5";
    files = let prefix = "sysa/${pname}-${version}"; in {
      makefile = "${prefix}/mk/main.mk";
    };
  };

  meta = with lib; {
    description = "GNU sed, a batch stream editor";
    homepage = "https://www.gnu.org/software/sed";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ emilytrau ];
    mainProgram = "sed";
    platforms = platforms.unix;
  };
} (''
  # Unpack
  ungz --file ${src} --output sed.tar
  untar --file sed.tar
  rm sed.tar
  cd sed-${version}
'' + lib.optionalString bootstrap ''
  # Configure
  cp ${lbFiles.makefile} Makefile
  catm config.h

  # Build
  make LIBC=mes

  # Check
  ./sed/sed --version

  # Install
  mkdir -p ''${out}/bin
  cp sed/sed ''${out}/bin
  chmod 555 ''${out}/bin/sed
'' + lib.optionalString (!bootstrap) ''
  # Configure
  export CC="tcc -static -DHAVE_FCNTL_H"
  export LD="tcc"
  bash ./configure \
    --build=${buildPlatform.config} \
    --host=${hostPlatform.config} \
    --disable-nls \
    --disable-dependency-tracking \
    --prefix=''${out}

  # Build
  make AR="tcc -ar"

  # Check
  ./sed/sed --version

  # Install
  make install
'')
