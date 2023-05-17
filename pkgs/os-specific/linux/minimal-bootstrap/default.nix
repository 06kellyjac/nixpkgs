{ lib
, config
, buildPlatform
, hostPlatform
}:

lib.makeScope
  # Prevent using top-level attrs to protect against introducing dependency on
  # non-bootstrap packages by mistake. Any top-level inputs must be explicitly
  # declared here.
  (extra: lib.callPackageWith ({ inherit lib config buildPlatform hostPlatform; } // extra))
  (self: with self; {
    inherit (callPackage ./utils.nix { }) fetchurl derivationWithMeta writeTextFile writeText runCommand;

    inherit (callPackage ./stage0-posix { }) kaem m2libc mescc-tools mescc-tools-extra;

    live-bootstrap-files = callPackage ./live-bootstrap-files { };

    mes = callPackage ./mes { };
    mes-libc = callPackage ./mes/libc.nix { };

    ln-boot = callPackage ./ln-boot { };

    tinycc-bootstrappable = callPackage ./tinycc/bootstrappable.nix { };
    tinycc-mes = callPackage ./tinycc/mes.nix { };

    gnupatch = callPackage ./gnupatch { tinycc = tinycc-mes; };

    gnumake = callPackage ./gnumake { tinycc = tinycc-mes; };

    coreutils = callPackage ./coreutils { tinycc = tinycc-mes; };

    bash_2_05 = callPackage ./bash/2.nix { tinycc = tinycc-mes; };

    gnused-boot = callPackage ./gnused { tinycc = tinycc-mes; bash = bash_2_05; bootstrap = true; };
    gnused = callPackage ./gnused { tinycc = tinycc-mes; bash = bash_2_05; gnused = gnused-boot; gnugrep = gnugrep-boot; };

    gnugrep-boot = callPackage ./gnugrep { tinycc = tinycc-mes; bash = bash_2_05; bootstrap = true; };
    gnugrep = callPackage ./gnugrep { tinycc = tinycc-mes; bash = bash_2_05; gnugrep = gnugrep-boot; };

    gawk = callPackage ./gawk { tinycc = tinycc-mes; bash = bash_2_05; };

    gzip = callPackage ./gzip { tinycc = tinycc-mes; };

    heirloom-devtools = callPackage ./heirloom-devtools { tinycc = tinycc-mes; };

    gnutar = callPackage ./gnutar { tinycc = tinycc-mes; };

    flex-boot = callPackage ./flex {
      bash = bash_2_05;
      tinycc = tinycc-mes;
      bootstrap = true;
    };

    flex = callPackage ./flex {
      bash = bash_2_05;
      tinycc = tinycc-mes;
      bootstrap = false;
      flex = flex-boot;
    };

    musl = callPackage ./musl {
      bash = bash_2_05;
      tinycc = tinycc-mes;
    };

    gnum4 = callPackage ./gnum4 { tinycc = tinycc-mes; };
  })
