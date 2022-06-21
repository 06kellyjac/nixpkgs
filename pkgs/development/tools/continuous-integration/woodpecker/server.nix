{ lib, buildGoModule, fetchFromGitHub, mkYarnPackage, woodpecker-frontend }:
let
  inherit (import ./common.nix { inherit lib fetchFromGitHub; })
    meta
    version
    src
    ldflags
    postBuild
    ;
in
buildGoModule {
  pname = "woodpecker-server";
  inherit version src ldflags postBuild;
  vendorSha256 = null;

  postPatch = ''
    cp -r ${woodpecker-frontend} web/dist
  '';

  subPackages = "cmd/server";

  CGO_ENABLED = 1;

  # buildInputs = [
  #   glibc.static
  # ];

  # # FIXME: what about stdenv.hostPlatform.isMusl
  # cflags = [
  #   "-I${lib.getDev glibc}/include"
  # ];

  # ldflags = [
  #   "-s"
  #   "-w"
  #   ''-extldflags "-static"''
  #   "-X github.com/woodpecker-ci/woodpecker/version.Version=${version}"
  #   "-L ${lib.getLib glibc}/lib"
  # ];

  meta = meta // {
    description = "Woodpecker Continuous Integration server";
  };
}
