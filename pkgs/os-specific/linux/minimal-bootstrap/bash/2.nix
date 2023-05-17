{ lib
, derivationWithMeta
, runCommand
, fetchurl
, writeText
, tinycc
, gnumake
, gnupatch
, coreutils
, live-bootstrap-files

  # self for passthru
, bash_2_05
, mescc-tools-extra
}:
let
  pname = "bash";
  version = "2.05b";

  src = fetchurl {
    url = "mirror://gnu/bash/bash-${version}.tar.gz";
    sha256 = "1r1z2qdw3rz668nxrzwa14vk2zcn00hw7mpjn384picck49d80xs";
  };

  # Thanks to the live-bootstrap project!
  # See https://github.com/fosslinux/live-bootstrap/blob/1bc4296091c51f53a5598050c8956d16e945b0f5/sysa/bash-2.05b/bash-2.05b.kaem
  liveBootstrap = live-bootstrap-files.packageFiles {
    inherit pname version;
    parent = "sysa";
  };

  main_mk = liveBootstrap."mk/main.mk";

  common_mk = liveBootstrap."mk/common.mk";

  builtins_mk = liveBootstrap."mk/builtins.mk";

  patches = [
    # mes libc does not have locale support
    liveBootstrap."patches/mes-libc.patch"
    # int name, namelen; is wrong for mes libc, it is char* name, so we modify tinycc
    # to reflect this.
    liveBootstrap."patches/tinycc.patch"
    # add ifdef's for features we don't want
    liveBootstrap."patches/missing-defines.patch"
    # mes libc + setting locale = not worky
    liveBootstrap."patches/locale.patch"
    # We do not have /dev at this stage of the bootstrap, including /dev/tty
    liveBootstrap."patches/dev-tty.patch"
  ];
in
runCommand "${pname}-${version}" {
  inherit pname version;

  nativeBuildInputs = [
    tinycc
    gnumake
    gnupatch
    coreutils
  ];

  passthru.runCommand = name: env: buildCommand:
    derivationWithMeta ({
      inherit name;

      builder = "${bash_2_05}/bin/bash";
      args = [
        "-e"
        (writeText "bash-builder.sh" ''
          export SHELL=${bash_2_05}/bin/bash
          export CONFIG_SHELL=$SHELL
          bash -eux $buildCommandPath
        '')
      ];

      PATH = lib.makeBinPath ((env.nativeBuildInputs or []) ++ [ bash_2_05 mescc-tools-extra ]);
      inherit buildCommand;
      passAsFile = [ "buildCommand" ];
    } // (builtins.removeAttrs env [ "nativeBuildInputs" ]));

  meta = with lib; {
    description = "GNU Bourne-Again Shell, the de facto standard shell on Linux";
    homepage = "https://www.gnu.org/software/bash";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ emilytrau ];
    platforms = platforms.unix;
  };
} ''
  # Unpack
  ungz --file ${src} --output bash.tar
  untar --file bash.tar
  rm bash.tar
  cd bash-2.05b

  # Patch
  ${lib.concatMapStringsSep "\n" (f: "patch -Np0 -i ${f}") patches}

  # Configure
  cp ${main_mk} Makefile
  cp ${builtins_mk} builtins/Makefile
  cp ${common_mk} common.mk
  touch config.h
  touch include/version.h
  touch include/pipesize.h

  # Build
  make mkbuiltins
  cd builtins
  make libbuiltins.a
  cd ..
  make

  # Check
  ./bash --version

  # Install
  install -D bash ''${out}/bin/bash
  ln -s ''${out}/bin/bash ''${out}/bin/sh
''
