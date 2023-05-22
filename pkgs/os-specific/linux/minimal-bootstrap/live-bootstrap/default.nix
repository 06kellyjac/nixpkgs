{ lib, fetchurl, runCommand, gnutar, sources ? import ./sources.nix }:
rec {
  copies = {
    "1bc4296091c51f53a5598050c8956d16e945b0f5" = unpackLiveBootstrap "1bc4296091c51f53a5598050c8956d16e945b0f5" "0s7spx3jbmflp8vr0hkr466nwn92wy56r0wxx4lmkrdp7a6hs8mc";
    "e86db47b6ee40d68e26866dd15e8637f64d6d778" = unpackLiveBootstrap "e86db47b6ee40d68e26866dd15e8637f64d6d778" "14bdxyg16ngcw53mfvjq2khqrdf2f3zp0r3fgwdgg63dzi4wkf0b";
  };
  raw = {
    "1bc4296091c51f53a5598050c8956d16e945b0f5" = fetchurl {
      url = "https://github.com/fosslinux/live-bootstrap/archive/1bc4296091c51f53a5598050c8956d16e945b0f5.tar.gz";
      sha256 = "0s7spx3jbmflp8vr0hkr466nwn92wy56r0wxx4lmkrdp7a6hs8mc";
    };
  };
  unpackLiveBootstrap = commit: sha256:
    let
      pname = "live-bootstrap";
      version = commit;
      src = fetchurl {
        url = "https://github.com/fosslinux/live-bootstrap/archive/${commit}.tar.gz";
        inherit sha256;
      };
    in
    runCommand "live-bootstrap-${lib.substring 0 7 commit}-files" { nativeBuildInputs = [ gnutar ]; } ''
      # Unpack
      ungz --file ${src} --output live-bootstrap.tar
      mkdir ''${out}
      tar tvf live-bootstrap.tar
      bob
      cd ''${out}
      untar --non-strict --file ''${NIX_BUILD_TOP}/live-bootstrap.tar
      # # run with old archive compatibility
      # tar --delete --file=live-bootstrap.tar live-bootstrap-e86db47b6ee40d68e26866dd15e8637f64d6d778/sysc
      # tar --exclude='*sysc*' --atime-preserve -mxvkf live-bootstrap.tar -C ''${out}
    '';
}
