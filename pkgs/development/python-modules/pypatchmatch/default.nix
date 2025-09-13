{
  lib,
  stdenv,
  fetchPypi,
  buildPythonPackage,
  pythonOlder,
  pythonAtLeast,
  python,

  pkg-config,

  setuptools,
  wheel,

  opencv,

  numpy,
  pillow,
  tqdm,
}:
buildPythonPackage rec {
  pname = "pypatchmatch";
  version = "1.0.2";
  pyproject = true;
  disabled = pythonOlder "3.9" || pythonAtLeast "3.13";

  # no tags on github
  src = fetchPypi {
    inherit version;
    pname = "PyPatchMatch";
    hash = "sha256-fgHjMs3/oIKgwP11LrdkQWfo9OUpe0ZPUBQY6ucHm0E=";
  };

  build-system = [
    setuptools
    wheel
  ];

  # unpin setuptools, can't use pythonRelaxDepsHook at this stage
  preBuild = ''
    substituteInPlace pyproject.toml \
      --replace-fail "setuptools == 67.1.0" "setuptools"

    make -C patchmatch
  '';

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    opencv
  ];

  dependencies = [
    numpy
    pillow
    tqdm
  ];

  postInstall = ''
    install -D ./patchmatch/libpatchmatch.so "$out/${python.sitePackages}/patchmatch"
  '';

  pythonImportsCheck = [ "patchmatch" ];

  meta = {
    description = "PatchMatch based image inpainting for C++ and Python";
    homepage = "https://github.com/mauwii/PyPatchMatch/";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      jk
    ];
  };
}
