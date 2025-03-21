{
  lib,
  stdenv,
  fetchurl,
  curl,
  libiconv,
}:

stdenv.mkDerivation rec {
  pname = "html-xml-utils";
  version = "8.7";

  src = fetchurl {
    url = "https://www.w3.org/Tools/HTML-XML-utils/${pname}-${version}.tar.gz";
    sha256 = "sha256-iIoxYxp6cDCLsvMz4HfQQW9Lt4MX+Gl/+0qVGH9ncwE=";
  };

  buildInputs = [
    curl
    libiconv
  ];

  meta = with lib; {
    description = "Utilities for manipulating HTML and XML files";
    homepage = "https://www.w3.org/Tools/HTML-XML-utils/";
    license = licenses.w3c;
    platforms = platforms.all;
  };
}
