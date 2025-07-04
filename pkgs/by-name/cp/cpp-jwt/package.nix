{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  openssl,
  gtest,
  nlohmann_json,
}:

stdenv.mkDerivation rec {
  pname = "cpp-jwt";
  version = "1.5";

  src = fetchFromGitHub {
    owner = "arun11299";
    repo = "cpp-jwt";
    rev = "v${version}";
    sha256 = "sha256-l1FevNhGX7vouKmGh/ypCcmZQLMpHJ4JFUp5dnNMEwg=";
  };

  cmakeFlags = [
    "-DCPP_JWT_USE_VENDORED_NLOHMANN_JSON=OFF"
    "-DCPP_JWT_BUILD_EXAMPLES=OFF"
  ];

  nativeBuildInputs = [ cmake ];

  buildInputs = [
    gtest
    openssl
    nlohmann_json
  ];

  doCheck = true;

  strictDeps = true;

  meta = {
    description = "JSON Web Token library for C++";
    homepage = "https://github.com/arun11299/cpp-jwt";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ fpletz ];
  };
}
