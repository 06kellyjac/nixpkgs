{ lib
, buildPlatform
, hostPlatform
, fetchurl
, bash
, tinycc
, musl
, pass ? 1
, runCommand
}:
let
  pname = "tcc-musl-pass${builtins.toString pass}";
  # # last version that can be compiled with mes-libc
  # version = "0.9.27";
  # rev = "d348a9a51d32cece842b7885d27a411436d7887b";

  # # src = fetchurl {
  # #   url = "mirror://gnu/sed/sed-${version}.tar.gz";
  # #   sha256 = "0006gk1dw2582xxvgx6y6rzs9zw8b36rhafjwm288zqqji3qfrf3";
  # # };

  # # Thanks to the live-bootstrap project!
  # # See https://github.com/fosslinux/live-bootstrap/blob/1bc4296091c51f53a5598050c8956d16e945b0f5/sysa/sed-4.0.9/sed-4.0.9.kaem
  # src = fetchurl {
  #   name = "tinycc-${version}.tar.gz";
  #   url = "https://repo.or.cz/tinycc.git/snapshot/${rev}.tar.gz";
  #   sha256 = "11idrxbwfgj1d03crv994mpbbbyg63j1k64lw1gjy7mkiifw2xap";
  # };
  # tccPrevSrc = fetchurl {
  #   name = "tinycc-0.9.26.tar.gz";
  #   url = "https://repo.or.cz/tinycc.git/snapshot/d5e22108a0dc48899e44a158f91d5b3215eb7fe6.tar.gz";
  #   sha256 = "11idrxbwfxj1d03crv994mpbbbyg63j1k64lw1gjy7mkiifw2xap";
  # };
  # # https://repo.or.cz/tinycc.git/snapshot/d5e22108a0dc48899e44a158f91d5b3215eb7fe6.tar.gz
  version = "unstable-2023-04-20";
  rev = "86f3d8e33105435946383aee52487b5ddf918140";

  src = fetchurl {
    name = "tinycc-${rev}.tar.gz";
    url = "https://repo.or.cz/tinycc.git/snapshot/${rev}.tar.gz";
    sha256 = "11idrvbwfgj1d03crv994mpbbbyg63j1k64lw1gjy7mkiifw2xap";
  };
in
bash.runCommand "${pname}-${version}" {
  inherit pname version;

  nativeBuildInputs = [
    tinycc
    # gnumake
    # coreutils
  ];

  meta = with lib; {
    description = "GNU sed, a batch stream editor";
    homepage = "https://www.gnu.org/software/sed";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ emilytrau ];
    mainProgram = "sed";
    platforms = platforms.unix;
  };
} ''
  # Unpack
  ungz --file ${src} --output tinycc.tar
  untar --file tinycc.tar
  rm tinycc.tar
  cd tinycc-${builtins.substring 0 7 rev}

  # Configure


  # Build
  tcc \
    -v \
    -static \
    -o ''${bindir}/tcc \
    -D TCC_TARGET_I386=1 \
    -D CONFIG_TCCDIR=\"${libdir}/tcc\" \
    -D CONFIG_TCC_CRTPREFIX=\"${libdir}\" \
    -D CONFIG_TCC_ELFINTERP=\"/mes/loader\" \
    -D CONFIG_TCC_LIBPATHS=\"${libdir}:${libdir}/tcc\" \
    -D CONFIG_TCC_SYSINCLUDEPATHS=\"${prefix}/include\" \
    -D TCC_LIBGCC=\"${libdir}/libc.a\" \
    -D CONFIG_TCC_STATIC=1 \
    -D CONFIG_USE_LIBGCC=1 \
    -D TCC_VERSION=\"0.9.27\" \
    -D ONE_SOURCE=1 \

    -o ''${out}/bin/tcc \
    -I . \
    -D TCC_TARGET_I386=1 \
    -D CONFIG_TCCDIR=\"''${out}/lib\" \
    -D CONFIG_TCC_CRTPREFIX=\"''${out}/lib\" \
    -D CONFIG_TCC_ELFINTERP=\"\" \
    -D CONFIG_TCC_LIBPATHS=\"''${out}/lib\" \
    -D CONFIG_TCC_SYSINCLUDEPATHS=\"${musl}/include:./include\" \
    -D TCC_LIBGCC=\"libc.a\" \
    -D TCC_LIBTCC1=\"libtcc1.a\" \
    -D CONFIG_TCCBOOT=1 \
    -D CONFIG_TCC_STATIC=1 \
    -D CONFIG_USE_LIBGCC=1 \
    -D TCC_MES_LIBC=1 \
    -D TCC_VERSION=\"${version}\" \
    -D ONE_SOURCE=1 \
    tcc.c

  # Check
  ./sed/sed --version

  # Install
  make install
''


# ln -sf "${PREFIX}/lib/mes/tcc/libtcc1.a" ./libtcc1.a

# for TCC in tcc-0.9.26 ./tcc-musl; do
#     "${TCC}" \
#         -v \
#         -static \
#         -o tcc-musl \
#         -D TCC_TARGET_I386=1 \
#         -D CONFIG_TCCDIR=\""${LIBDIR}/tcc"\" \
#         -D CONFIG_TCC_CRTPREFIX=\""${LIBDIR}"\" \
#         -D CONFIG_TCC_ELFINTERP=\"/musl/loader\" \
#         -D CONFIG_TCC_LIBPATHS=\""${LIBDIR}:${LIBDIR}/tcc"\" \
#         -D CONFIG_TCC_SYSINCLUDEPATHS=\""${PREFIX}/include/musl"\" \
#         -D TCC_LIBGCC=\""${LIBDIR}/libc.a"\" \
#         -D CONFIG_TCC_STATIC=1 \
#         -D CONFIG_USE_LIBGCC=1 \
#         -D TCC_VERSION=\"0.9.27\" \
#         -D ONE_SOURCE=1 \
#         -B . \
#         tcc.c

#     # libtcc1.a
#     rm -f libtcc1.a
#     ${TCC} -c -D HAVE_CONFIG_H=1 lib/libtcc1.c
#     ${TCC} -ar cr libtcc1.a libtcc1.o


# /x86/bin/simple-patch /sysa/tcc-0.9.27/build/tcc-0.9.27/tcctools.c \
#     /sysa/tcc-0.9.27/simple-patches/remove-fileopen.before /sysa/tcc-0.9.27/simple-patches/remove-fileopen.after
# /x86/bin/simple-patch /sysa/tcc-0.9.27/build/tcc-0.9.27/tcctools.c \
#     /sysa/tcc-0.9.27/simple-patches/addback-fileopen.before /sysa/tcc-0.9.27/simple-patches/addback-fileopen.after
# /x86/bin/simple-patch /sysa/tcc-0.9.27/build/tcc-0.9.27/tccelf.c \
#     /sysa/tcc-0.9.27/simple-patches/fiwix-paddr.before /sysa/tcc-0.9.27/simple-patches/fiwix-paddr.after
# # Fix SIGSEGV while building lwext4
# /x86/bin/simple-patch /sysa/tcc-0.9.27/build/tcc-0.9.27/tccelf.c \
#     /sysa/tcc-0.9.27/simple-patches/check-reloc-null.before /sysa/tcc-0.9.27/simple-patches/check-reloc-null.after
# # Compile
# tcc-0.9.26 \
#     -v \
#     -static \
#     -o ${bindir}/tcc \
#     -D TCC_TARGET_I386=1 \
#     -D CONFIG_TCCDIR=\"${libdir}/tcc\" \
#     -D CONFIG_TCC_CRTPREFIX=\"${libdir}\" \
#     -D CONFIG_TCC_ELFINTERP=\"/mes/loader\" \
#     -D CONFIG_TCC_LIBPATHS=\"${libdir}:${libdir}/tcc\" \
#     -D CONFIG_TCC_SYSINCLUDEPATHS=\"${prefix}/include\" \
#     -D TCC_LIBGCC=\"${libdir}/libc.a\" \
#     -D CONFIG_TCC_STATIC=1 \
#     -D CONFIG_USE_LIBGCC=1 \
#     -D TCC_VERSION=\"0.9.27\" \
#     -D ONE_SOURCE=1 \
#     tcc.c
