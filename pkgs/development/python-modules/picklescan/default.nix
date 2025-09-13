{
  lib,
  fetchFromGitHub,
  buildPythonPackage,
  pythonOlder,

  setuptools,

  pytestCheckHook,

  aiohttp,
  numpy_1,
  pip,
  py7zr,
  requests,
  tkinter,
}:
buildPythonPackage rec {
  pname = "picklescan";
  version = "0.0.31";
  pyproject = true;
  disabled = pythonOlder "3.9";

  src = fetchFromGitHub {
    owner = "mmaitre314";
    repo = "picklescan";
    rev = "v${version}";
    hash = "sha256-rhiPOwtZ852vRNqbcpw7FPfenyIzJ9Zmr8OirWL25mk=";
  };

  build-system = [
    setuptools
  ];

  dependencies = [ ];

  optional-dependencies = {
    test = [
      aiohttp
      numpy_1
      pip
      py7zr
      requests
      tkinter
    ];
  };

  pythonImportsCheck = [ "picklescan" ];
  nativeCheckInputs = [
    pytestCheckHook
  ]
  ++ lib.flatten (builtins.attrValues optional-dependencies);

  meta = {
    description = "Security scanner detecting Python Pickle files performing suspicious actions";
    homepage = "https://github.com/mmaitre314/picklescan/";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      jk
    ];
  };
}
