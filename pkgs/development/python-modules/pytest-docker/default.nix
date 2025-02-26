{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  wheel,
}:

buildPythonPackage rec {
  pname = "pytest-docker";
  version = "3.2.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "avast";
    repo = "pytest-docker";
    rev = "v${version}";
    hash = "sha256-omz2X1Llt81GZ8GmgrQjXjPJMmSuY7/eXlukZPgJrBc=";
  };

  build-system = [
    setuptools
    wheel
  ];

  pythonImportsCheck = [
    "pytest_docker"
  ];

  meta = {
    description = "Docker-based integration tests";
    homepage = "https://github.com/avast/pytest-docker";
    changelog = "https://github.com/avast/pytest-docker/blob/${src.rev}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
  };
}
