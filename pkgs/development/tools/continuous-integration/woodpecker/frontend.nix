{ lib, fetchFromGitHub, mkYarnPackage }:
let
  inherit (import ./common.nix { inherit lib fetchFromGitHub; })
    meta
    version
    src
    ;
in
mkYarnPackage {
  pname = "woodpecker-frontend";
  inherit version;

  src = "${src}/web";

  packageJSON = ./woodpecker-package.json;
  yarnLock = "${src}/web/yarn.lock";

  buildPhase = ''
    yarn build
  '';

  installPhase = ''
    runHook preInstall

    cp -R deps/woodpecker-ci/dist $out
    echo "${version}" > "$out/version"

    runHook postInstall
  '';

  # Do not attempt generating a tarball for woodpecker-frontend again.
  doDist = false;

  meta = meta // {
    description = "Woodpecker Continuous Integration server frontend";
  };
}
