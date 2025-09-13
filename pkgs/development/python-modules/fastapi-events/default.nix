{
  lib,
  fetchFromGitHub,
  buildPythonPackage,
  pythonOlder,
}:
buildPythonPackage rec {
  pname = "fastapi-events";
  version = "0.12.2";
  format = "setuptools";
  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "melvinkcx";
    repo = "fastapi-events";
    rev = "v${version}";
    hash = "sha256-YOaUWv8luypHzKs7kDLl0Z9f34HPmhMoExagkYiwdl8=";
  };

  pythonImportsCheck = [ "fastapi_events" ];
  # tests need a variety of unpackaged libraries

  meta = {
    description = "Asynchronous event dispatching/handling library for FastAPI and Starlette";
    homepage = "https://github.com/melvinkcx/fastapi-events/";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      jk
    ];
  };
}
