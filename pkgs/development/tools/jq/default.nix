{ lib
, stdenv
, fetchurl
, autoreconfHook
, bison
, onigurumaSupport ? true
, oniguruma
}:

stdenv.mkDerivation rec {
  pname = "jq";
  version = "1.7rc1";

  # Note: do not use fetchpatch or fetchFromGitHub to keep this package available in __bootPackages
  src = fetchurl {
    url = "https://github.com/jqlang/jq/releases/download/jq-${version}/jq-${version}.tar.gz";
    sha256 = "sha256-pqeDfLRsYahmZGf+8GdU/lO5XBYmtUFq2ljt/hOT2sM=";
  };

  outputs = [ "bin" "doc" "man" "dev" "lib" "out" ];

  # Upstream script that writes the version that's eventually compiled
  # and printed in `jq --help` relies on a .git directory which our src
  # doesn't keep.
  preConfigure = ''
    echo "#!/bin/sh" > scripts/version
    echo "echo ${version}" >> scripts/version
    patchShebangs scripts/version
  '';

  # paranoid mode: make sure we never use vendored version of oniguruma
  # Note: it must be run after automake, or automake will complain
  preBuild = ''
    rm -r ./modules/oniguruma
  '';

  buildInputs = lib.optionals onigurumaSupport [ oniguruma ];
  nativeBuildInputs = [ autoreconfHook bison ];

  # Darwin requires _REENTRANT be defined to use functions like `lgamma_r`.
  # Otherwise, configure will detect that they’re in libm, but the build will fail
  # with clang 16+ due to calls to undeclared functions.
  # This is fixed upstream and can be removed once jq is updated (to 1.7 or an unstable release).
  env.NIX_CFLAGS_COMPILE = lib.optionalString stdenv.isDarwin (toString [
    "-D_REENTRANT=1"
    "-D_DARWIN_C_SOURCE=1"
  ]);

  configureFlags = [
    "--bindir=\${bin}/bin"
    "--sbindir=\${bin}/bin"
    "--datadir=\${doc}/share"
    "--mandir=\${man}/share/man"
  ] ++ lib.optional (!onigurumaSupport) "--with-oniguruma=no"
  # jq is linked to libjq:
  ++ lib.optional (!stdenv.isDarwin) "LDFLAGS=-Wl,-rpath,\\\${libdir}";

  doInstallCheck = true;
  installCheckTarget = "check";

  postInstallCheck = ''
    $bin/bin/jq --help >/dev/null
    $bin/bin/jq -r '.values[1]' <<< '{"values":["hello","world"]}' | grep '^world$' > /dev/null
  '';

  passthru = { inherit onigurumaSupport; };

  meta = with lib; {
    description = "A lightweight and flexible command-line JSON processor";
    longDescription = ''
      jq is like sed for JSON data - you can use it to slice and filter and map
      and transform structured data with the same ease that sed, awk, grep and
      friends let you play with text.

      jq is written in portable C, and it has zero runtime dependencies. You can
      download a single binary, scp it to a far away machine of the same type,
      and expect it to work.

      jq can mangle the data format that you have into the one that you want
      with very little effort, and the program to do so is often shorter and
      simpler than you'd expect.
    '';
    homepage = "https://jqlang.github.io/jq/";
    license = licenses.mit;
    maintainers = with maintainers; [ raskin globin artturin jk ];
    platforms = platforms.unix;
    downloadPage = "https://jqlang.github.io/jq/download/";
  };
}
