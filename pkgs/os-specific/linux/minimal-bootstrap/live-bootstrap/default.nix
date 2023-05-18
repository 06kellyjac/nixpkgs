{ lib, fetchurl, runCommand, sources ? import ./sources.nix }:
rec {
  getLBFiles = { commit, files }:
    let
      source = sources.${commit};
      src = fetchurl {
        url = "https://github.com/fosslinux/live-bootstrap/archive/${commit}.tar.gz";
        inherit (source) sha256;
      };
      unpacked = unpackLiveBootstrap { inherit commit src; files = source.files; };
    in
    lib.mapAttrs' (n: v: lib.nameValuePair n "${unpacked}/${v}") files;

  unpackLiveBootstrap = { commit, files, src }:
    runCommand "live-bootstrap-${lib.substring 0 7 commit}-files" {
      pname = "live-bootstrap";
      version = "${commit}";
    }
    ''
      # Unpack
      ungz --file ${src} --output live-bootstrap.tar
      untar --non-strict --file live-bootstrap.tar
      rm live-bootstrap.tar
      cd live-bootstrap-${commit}

      # Install
      ${lib.concatLines (map (f:
        let dir = builtins.dirOf f; in ''
          mkdir -p ''${out}/${dir}
          cp ${f} ''${out}/${dir}
        ''
      ) files)}
    '';
}
